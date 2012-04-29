class Action < ActiveRecord::Base
  require 'fileutils'
  include ApplicationHelper

  belongs_to :project
      
  
  def prepare
    in_working_dir do 
      #create temp folder (by self.id)
      FileUtils.rm_rf("action_#{self.id}")
      Dir.mkdir("action_#{self.id}")

      src = Dir.open("project_#{self.project_id}/#{self.project.repo_path}/")
      dest= Dir.open("action_#{self.id}")

      FileUtils.cp_r(src, dest)

    end
    #clone the projects source git into temp folder
    #run the command line action in the temp folder and store result.
    #
  end
end
