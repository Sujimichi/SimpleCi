class Action < ActiveRecord::Base
  belongs_to :project

  def in_working_dir 
    begin
      Dir.chdir(SimpleCi::WorkingDir)
    rescue
      `mkdir '#{SimpleCi::WorkingDir}`
      #Dir.mkdir(SimpleCi::WorkingDir)
      Dir.chdir(SimpleCi::WorkingDir)
    end
  end

  def run
    in_working_dir
    Dir.mkdir("action_#{self.id}")
    #create temp folder (by self.id)
    #clone the projects source git into temp folder
    #run the command line action in the temp folder and store result.
    #
  end
end
