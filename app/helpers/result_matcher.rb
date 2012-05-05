class ResultMatcher
  def initialize result
    @result = result
  end
end

class UnknownMatcher < ResultMatcher
  def process
    @result.evaluate_results do |result, output|
      output = {
        :status => :unrecognised_result,
        :message => "result was not recognised",
        :summary => "unknown"
      }

    end
  end
end

class RspecMatcher < ResultMatcher
  def process
    @result.evaluate_results do |result, output|
      output[:status] = :failure
      return output if result.blank?

      output[:summary] = result.split("\n").select{|line| line.match(/^(\d+) examples/) }.join
      output[:time] = result.split("\n").select{|line| line.match(/^Finished in/)}.join.sub("Finished in","")

      if output[:summary].include?("0 failures")
        output[:status] = :success
      else
        output[:status] = :failure
      end
    end
  end
end

class CucumberMatcher < ResultMatcher
  def process
    @result.evaluate_results do |result, output|
      output[:status] = :failure
      return output if result.blank?

      [0, 31, 32, 36, 90].each{|i| result.gsub!("\e[#{i}m","") } #remove unicode chars
      output[:altered_result] = result #altered_result will be shown instead of result
      output[:summary] = result.split("\n").select{|line| line.match(/^(\d+) scenarios/) }.join
      output[:time] = result.split("\n").last

      if output[:summary].include?("fail")
        output[:status] = :failure
      else
        output[:status] = :success       
      end
    end
  end
end
