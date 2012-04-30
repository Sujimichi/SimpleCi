#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

SimpleCi::Application.load_tasks


#Rake tasks for controling numbers of active workers
namespace :workers do
  require "#{Rails.root}/lib/workers"

  task :start,[:count] do |t, args|
    count = args[:count]
    unless Workers.count.eql?(0)
      puts "Stopping #{Workers.count} active workers"
      stop_thread = Workers.stop
      stop_thread.join if stop_thread #wait for thread to finish
    end
    puts "Starting Workers"
    Workers.start(count)
  end

  task :stop do
    unless Workers.count.eql?(0)
      puts "Stopping #{Workers.count} active workers"
      Workers.stop
    end
  end

  task :count do
    puts "\nCurrent worker count: #{Workers.count}\n\n"
  end

  task :reset do
    require "#{Rails.root}/config/environment"
    count = Workers.count
    count = nil if count.eql?(0)
    stop_thread = Workers.stop
    stop_thread.join if stop_thread #wait for thread to finish
    Delayed::Job.destroy_all
    Workers.start(count)
  end

end


task :start_observer do 
  require "#{Rails.root}/config/environment"
  Delayed::Job.destroy_all
  Delayed::Job.enqueue(ObserverJob.new(60), :queue => "command_queue")
end

task :reset do  
  system "rake db:drop:all && rake db:create:all && rake db:migrate && rake db:test:prepare"
end
