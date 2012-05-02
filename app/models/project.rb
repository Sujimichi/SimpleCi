#Projects are the apps which SimpleCi will monitor.  Each project holds basic info ie: source repo url and provides some actions to control the project.
#
#When a project is created the initial_setup method is called.  This clones the source repo into a project specific dir in simple_ci/ in the home dir.  
#initial_setup will also call each command in setup_commands to be run within the cloned repo.  
#
#
class Project < ActiveRecord::Base
  require 'fileutils'
  include ApplicationHelper

  has_many :actions
  has_many :results


  after_create do 
    #Delayed::Job.enqueue(SetupProjectJob.new(self.id), :queue => :command_queue)
  end


  def setup_commands
    ["bundle install", "mkdir tmp && mkdir tmp/pids", "bundle exec rake db:create:all", "bundle exec rake db:migrate","bundle exec rake db:test:prepare"]
  end

  def update_commands
    ["bundle exec rake db:migrate","bundle exec rake db:test:prepare"]
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
      
      setup_commands.each do |command|
        Bundler.with_clean_env do
          `#{command}`
        end
      end

    end
  end

  def update_repo
    updated = ""
    in_working_dir do 
      if Dir.open("./").to_a.include?("project_#{self.id}")
        Dir.chdir("project_#{self.id}/#{self.repo_path}")
        updated = `git pull origin master`
      else
        initial_setup
        return true
      end
    end
    
    !updated.downcase.include?("already up-to-date")
  end

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
  def poll
    do_work if update_repo || self.results.empty?
  end

  def basic_poll
    if update_repo || self.results.empty?
      self.actions.each do |action|
        action.prepare
        action.run_command
      end
    end
  end

end
