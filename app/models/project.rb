#A project represents a repository which is being monitored.  Each project holds basic info ie: source repo url.
#A project also define setup and maintaince actions (ie rake tasks) to initilize and update the repo.
#
#Once a project has been created it will be initialised by the background poller (either Runner or ObserverJob *see note about running modes) 
#Initialization involves cloning the projects source repo into a project folder (name project_<id>) in the working directory (SimpleCi::WorkingDir (default ~/simple_ci/.  Once cloned each of the setup commands are then run in the project folder.  
#This completes initialization.  At any stage the project folder can be deleted and it will just be re-initialized when the background poller comes back to it.  (deleting it during some action running in that dir might be interesting).
#
#Once a project is initialized the background poller periodically checks the source repo for changes.  If any are found they are pulled to the repo in the project folder and any update commands are run.  
#
#Once initialised if the project has any actions then the poller will run these.  Once an action has completed it stores the response in a new Result object.  Note! - Actions are processed in parrallel and in different dirs, which is tricker than changing plane at Ohare.  See more on Action about this.
#
class Project < ActiveRecord::Base
  require 'fileutils'
  include ApplicationHelper

  has_many :actions
  has_many :results

  def active_actions
    self.actions.where(:active => true)
  end

  def setup_commands    
    s = super
    s.gsub("'","")
  end

  def update_commands
    s = super
    s.gsub("'","")
  end

  def run_commands command = :setup
    if command.eql?(:setup)
      commands = setup_commands.split("\n") 
      act = "project_#{self.id}_initializing"
    elsif command.eql?(:update)
      commands = update_commands.split("\n") 
      act = "project_#{self.id}_updating"
    end

    commands.each do |command|
      Rails.cache.write(act, command.inspect)
      puts "Running #{command}"
      Bundler.with_clean_env { `#{command}` }
    end

    Rails.cache.write(act, false)
  end

  def initial_setup
    in_working_dir do 
      FileUtils.rm_rf("project_#{self.id}")
      Dir.mkdir("project_#{self.id}")
      Dir.chdir("project_#{self.id}")
      path = `git clone #{self.source_path}`
      repo_dir = path.split("project_#{self.id}/").last.split("/").first
      self.update_attributes(:repo_path => repo_dir)
      Dir.chdir(repo_dir)
      run_commands(:setup)
    end
  end

  def update_repo
    updated = ""
    in_working_dir do 
      if Dir.open("./").to_a.include?("project_#{self.id}")
        Dir.chdir("project_#{self.id}/#{self.repo_path}")
        r = `git pull origin master`
        updated = !r.downcase.include?("already up-to-date")

        run_commands(:update) if updated
      else
        initial_setup
        return true
      end
    end    
    updated
  end

  #do_work should only be used when working with background workers
  #user Runner to work with threads or basic_poll for sequential processing
  def do_work
    self.actions.each do |action|
      action.prepare
    end

    self.actions.each do |action|
      job = RunCommandJob.new(action.id)  #create a job to run the actions command
      Delayed::Job.enqueue(job, :queue => "command_queue") #and add it to the worker queue 
    end
  end

  #pull from the source repo and if any changes call do_work
  #poll (which calls do_work) should only be used when working with background workers
  def poll
    do_work if update_repo || self.results.empty?
  end

  #processes the actions sequentialy without threads or background workers
  def basic_poll
    if update_repo || self.results.empty?
      self.actions.each do |action|
        action.prepare
        action.run_command
      end
    end
  end

end
