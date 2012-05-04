class Action < ActiveRecord::Base
  require 'fileutils'
  include ApplicationHelper

  belongs_to :project
  has_many :results


  #Ensure the actions dir is present and copies the projects app dir into it
  #
  #Each action creates a directory for itself ie: action_<action.id> and takes a copy (not clone) of the repo in the projects dir.  
  #The project will have cloned the source repo and run setup commands so that dir is ready for commands to be run.
  #Each action has a separate dir to isolate the actions from each other.
  def prepare
    in_working_dir do 
      #create temp folder (remove it first if already present)
      FileUtils.rm_rf("action_#{self.id}")
      Dir.mkdir("action_#{self.id}")

      #copy the app dir from the projects dir into the actions dir.
      src = Dir.open("project_#{self.project_id}/#{self.project.repo_path}/")
      dest= Dir.open("action_#{self.id}")
      FileUtils.cp_r(src, dest)
    end
  end

  #Assuming that prepare has been called, run the command line stored on 'command' inside the app folder for this action
  def run_command args = {:return_thread => false}

    return if Rails.cache.fetch("action_#{self.id}:started") #prevent calling when already running.
    Rails.cache.write("action_#{self.id}:started", true)

    thread = nil
        
    in_working_dir do 

      Dir.chdir("action_#{self.id}")
      repo_path = Dir.open("./").to_a.select{|d| !['.','..','temp'].include?(d)}.first 
      #repo_path ||= self.project.repo_path

      Dir.chdir(repo_path) #go into the app dir within the actions' dir

      thread = (Rails.env.eql?("test") ? FakeThread : Thread).new{
        command_response = nil
        log = nil
        Bundler.with_clean_env do 
          log = `git log -n 1`  #get the last commit log
          command_response = `#{self.command}` #Run the command (yes yes no safty catches here yet, this is a dev tool!)
        end
        commit_id = log.split(" ")[1] #get the commit id from the log.

        #Create a result and store the data returned by the command, the commit_it and project and action ids     
        result = Result.new(
          :action => self, 
          :project_id => self.project_id, 
          :data => command_response, 
          :commit_id => commit_id, 
          :command => self.command, 
          :full_log => log, 
          :result_matcher => self.result_matcher
        )
        result.save

        ActiveRecord::Base.connection.close #close connection to DB
        Rails.cache.write("action_#{self.id}:started", false)

      }

    end

    if args[:return_thread]
      return thread
    else
      thread.join
    end
  end
end
