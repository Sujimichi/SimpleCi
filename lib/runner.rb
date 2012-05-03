class Runner

  def self.start
    runner = Runner.new
    runner.do_process
  end


  def do_process
    @sleep = 30

    puts "checking projects..."
    threads = []    
    to_run = []


    Project.all.each do |project|
      if project.update_repo || project.results.empty? || Rails.cache.fetch("force_update")
        puts "updating project #{project.name}"
        project.actions.each do |action| 
          action.prepare
          to_run << action
        end
      end
    end

    to_run.each do |action|
      threads << action.run_command(:return_thread => true)
    end

    threads.each{|t| t.join}

    if to_run.empty?
      puts "sleeping..."
      sleep @sleep
    end

    do_process
  end

end
