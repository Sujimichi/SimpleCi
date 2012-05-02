class Result < ActiveRecord::Base
  belongs_to :project
  belongs_to :action

  validates :commit_id, :presence => true

  


  def display
    return @display unless @display.nil?

    matchers = {:rspec => RspecMatcher, :cucumber => CucumberMatcher}


    matcher_type = :rspec 
    if self.action
      matcher_type = :rspec if self.action.command.include?("rspec")
      matcher_type = :cucumber if self.action.command.include?("cucumber")
    end

    matcher = matchers[matcher_type].new(self)

    @display = matcher.process
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

      output[:summary] = result.split("\n").select{|line| line.match(/^(\d+) examples/) }.join
      
      if output[:summary].include?("0 failures")
        output[:status] = :success
      else
        output[:status] = :failure
      end
      
      output[:seconds] = result.split("Finished in").last.split("seconds").first.to_f
    end
  end

end

class CucumberMatcher < ResultMatcher

  def process
    @result.evaluate_results do |result, output|
      output[:status] = :failure
      return output if result.blank?


      [0, 31, 32, 36, 90].each do |i|
        result.gsub!("\e[#{i}m","")
      end

      
      output[:altered_result] = result

      summary = result.split("\n").select{|line| line.match(/^(\d+) scenarios/) }

      output[:summary] = summary.join


      if summary.include?("fail")
        output[:status] = :success
      else
        output[:status] = :failure
      end

      

      output[:seconds] = result.split("\n").last
    end
  end

end


