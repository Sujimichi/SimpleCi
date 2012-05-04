class Runner
  attr_accessor :stop, :threads

  def self.start
    runner = Runner.new
    runner.do_process
  end

  def initialize
    @sleep = 15
    @stop = false
    @threads = []
  end

  def halt
    @stop = true
    @threads.compact.each{|t| t.join}
  end

  def do_process
    to_run = []
    threads = []


    Project.all.each do |project|
      puts "\nchecking project #{project.id}..."
 
      if project.update_repo || project.results.empty? || Rails.cache.fetch("force_update_project_#{project.id}")
        puts "\nupdating needed"
        project.active_actions.each do |action| 
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
      puts "\n\nsleeping..."
      sleep @sleep
    end

    do_process unless @stop
  end

=begin
  def initialize
    @semaphore = Mutex.new
    @stop = false
  end


  def check_projects 
    @semaphore.synchronize do 
      puts "flag up"
      puts "Checking Projects"
      Project.all.each do |project|      
        if project.update_repo || project.results.empty? || Rails.cache.fetch("force_update")
          puts "adding project #{project.id} actions to be processed"
          actions_to_process = Rails.cache.fetch("actions_to_process")
          actions_to_process ||= []
          actions_to_process << project.actions.map{|a| a.id}
          Rails.cache.write("actions_to_process", actions_to_process.flatten.uniq)
        end

      end
      puts "flag down"
    end

    sleep 10

    check_projects unless @stop
    
  end


  def process_actions
    actions = []
    threads = []
    @semaphore.synchronize do
      puts "flag up"
      action_ids = Rails.cache.fetch("actions_to_process")
      Rails.cache.write("actions_to_process", [])
      action_ids ||= []
      actions = Action.where(:id => action_ids)
      actions.each do |action|
        action.prepare
      end

      puts "flag down"
      puts Rails.cache.fetch("actions_to_process").inspect

    end

    actions.each do |action|
      threads << action.run_command(:return_thread => true)
    end

    threads.each{|t| t.join}

    puts "sleeping..."
    sleep 10

    process_actions unless @stop

  end
=end


end
