module ApplicationHelper
    
  def in_working_dir &blk
    initial_dir = Dir.getwd
    begin
      Dir.chdir(SimpleCi::WorkingDir)
    rescue
      Dir.mkdir(SimpleCi::WorkingDir)
      Dir.chdir(SimpleCi::WorkingDir)
    end
    yield
    Dir.chdir(initial_dir)
  end
end
