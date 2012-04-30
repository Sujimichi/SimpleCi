class ObserverJob
  def initialize delay = 60
    @delay = delay
  end

  def perform
    Project.all.each do |project|
      project.poll
    end

    sleep @delay
    Delayed::Job.enqueue(ObserverJob.new(@delay), :queue => "command_queue") #and add it to the worker queue 
  end
end

