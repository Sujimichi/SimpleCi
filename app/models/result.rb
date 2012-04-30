class Result < ActiveRecord::Base
  belongs_to :project
  belongs_to :action

end
