class Result < ActiveRecord::Base
  belongs_to :project
  belongs_to :action

  validates :commit_id, :presence => true

  def display
    return @display unless @display.nil?

    matchers = ResultMatcher.descendants.map{|m| {m.to_s.downcase.sub("matcher","").to_sym => m}}.inject{|i,j| i.merge(j)}
    #matchers = {:rspec => RspecMatcher, :cucumber => CucumberMatcher}
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
