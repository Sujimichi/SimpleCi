class Result < ActiveRecord::Base
  belongs_to :project
  belongs_to :action

  validates :commit_id, :presence => true

  def display
    return @display unless @display.nil?

    matchers = {:rspec => RspecMatcher, :cucumber => CucumberMatcher}
    matcher = matchers[self.result_matcher.to_sym]
    matcher ||= UnknownMatcher

    @display = matcher.new(self).process
  end

  def evaluate_results &blk
    output = {}
    log = self.full_log

    kindling = log.split("\n") #I'm sorry, I couldn't resist.  kindling from log.split
    output[:author] = kindling[1].sub("Author: ","")
    output[:commit_log] = kindling[3..kindling.size].join
    
    yield(self.data, output)
    return output
  end  

  def result_matcher
    s = super
    s = "" if s.nil?
    s
  end
end

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


