# Load the rails application
require File.expand_path('../application', __FILE__)

module SimpleCi
  
  WorkingDir = "#{ENV['home']}/simple_ci"

end

# Initialize the rails application
SimpleCi::Application.initialize!
