class Result < ActiveRecord::Base
  belongs_to :project
  belongs_to :action

  validates :commit_id, :presence => true

  def display
    return @dispaly unless @display.nil?
    matcher = RspecMatcher.new(self)
    @dispaly = matcher.process
  end

  def evaluate_results &blk
    output = {}
    yield(self.data, output)
    return output
  end  
end

class ResultMatcher
  def initialize result
    @result = result
  end
end

class RspecMatcher < ResultMatcher

  def process
    @result.evaluate_results do |result, output|
      output[:status] = :failure
      return output if result.blank?

      if result.include?("0 failures")
        output[:status] = :success
      else
        output[:status] = :failure
      end

      output[:seconds] = result.split("Finished in").last.split("seconds").first.to_f
    end
  end

end
