

module SimpleCi
  class Init
    opt = ARGV.shift

    

    case opt
    when "start"

      if ARGV.include?("--workers")
        if Dir.open("tmp/pids").to_a.join.include?("delayed_job")  
          puts "\nclearing up existing workers\n"
          system "script/delayed_job stop" 
        end
        worker_count = 3
        print "\nStarting Workers..."
        system "script/delayed_job -n #{worker_count} start"       
        puts "done"

        print "Adding Listener..."
        system "rake start_observer"
        puts "done"

      else
        puts "Starting Threaded Runner"
        runner_pid = Kernel.spawn("rake runner")
        puts "Runner forked. PID: #{runner_pid} - use kill #{runner_pid} to stop the runner"
      end

      puts "\nStarting Server..."
      exec "rails s"

    end

  end
end
