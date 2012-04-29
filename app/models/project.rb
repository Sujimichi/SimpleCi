class Project < ActiveRecord::Base
  require 'fileutils'
  include ApplicationHelper

  has_many :actions


  def setup_commands
    ["bundle exec rake db:create:all", "bundle exec rake db:migrate","bundle exec rake db:test:prepare"]
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
        system command
      end

    end
  end

  def do_work
    self.actions.each do |action|
      action.run
    end
  end


end
