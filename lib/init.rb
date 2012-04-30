

module SimpleCi
  class Init
    opt = ARGV.shift

    case opt
    when "start"

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

      puts "\nLaunching..."
      exec "rails s"

    end

  end
end
