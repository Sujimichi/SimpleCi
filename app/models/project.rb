class Project < ActiveRecord::Base
  has_many :actions


  def do_work
    self.actions.each do |action|
      action.run
    end
  end
end
