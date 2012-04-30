
#Container class which provides two class methods;
# Workers.start
# Workers.stop
#The command is simply passed to either of the Workers sub classes Workers::Local or Workers::Heroku depending on which environment it is running it.
class Workers
  Count = {:dev => 3, :production => 3}
  def self.start count = nil  #Start workers according to the current environment
    (Rails.env.eql?("production") ? Workers::Heroku : Workers::Local).start(count)
  end
  def self.stop   #Stop workers according to the current environment
    (Rails.env.eql?("production") ? Workers::Heroku : Workers::Local).stop    
  end
  def self.not_running?
    (Rails.env.eql?("production") ? Workers::Heroku.new : Workers::Local.new).not_running?
  end
  def self.count
    (Rails.env.eql?("production") ? Workers::Heroku.new : Workers::Local.new).count
  end
end


#Provides actions for starting and stopping Local background workers.
#Method for determining if workers are active is not 100% reliable.  It is possible for a worker to shutdown but not to clear its pid file.
#If that happens this logic believes that a worker is still active and will not try to start another one. 
#Its OK for development and test environments, this would not do in production!
class Workers::Local
  def self.start count = nil
    count = Workers::Count[:dev]  if count.blank?
    local_workers = Workers::Local.new 
    system "script/delayed_job -n #{count.to_i} start" if local_workers.not_running?
  end

  def self.stop  
    Thread.new{ 
      system "script/delayed_job stop"
    }
  end

  def running?
    Dir.open("#{Rails.root}/tmp/pids").to_a.join.include?("delayed_job")
    #File.exists?("#{Rails.root}/tmp/pids/delayed_job.0.pid") || File.exists?("#{Rails.root}/tmp/pids/delayed_job.pid")
    #above line is hacky and only OK in the development env.
  end

  def count
    Dir.open("#{Rails.root}/tmp/pids").to_a.select{|pid| pid.include?("delayed")}.size
  end

  def not_running?
    not running? #oh Ruby, you rock!
  end

  def start
    Workers::Local.start
  end
end

=begin

#Provides actions for starting and stopping heroku background workers.
#Uses the heroku api and has a requirment for the heroku username and password to be store in the heroku configs.
#It will only attempt to start workers if none are running.
class Workers::Heroku
  #require 'heroku'

  def initialize
    @heroku = Heroku::Client.new(ENV['HEROKU_USERNAME'], ENV['HEROKU_PASSWORD'])    
    @app = ENV['HEROKU_APP']
  end

  #set the number of heroku workers
  def set_to n
     @heroku.set_workers(@app, n)
  end

  #return true if heroku has 0 active workers.
  def not_running?
    @heroku.info(@app)[:workers].to_i.eql?(0) #return true if 0 workers
  end

  def count
    @heroku.info(@app)[:workers].to_i
  end

  #Start n workers on heroku.  n is defined in Workers::Count[environment]
  def self.start count = nil
    count = Workers::Count[:dev]  if count.blank?
    heroku_workers = Workers::Heroku.new  
    heroku_workers.set_to count.to_i if heroku_workers.not_running?
  end

  #Stop any active heroku workers.
  def self.stop
    heroku_workers = Workers::Heroku.new
    heroku_workers.set_to 0
  end

end

=end
