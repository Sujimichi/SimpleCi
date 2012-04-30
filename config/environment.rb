# Load the rails application
require File.expand_path('../application', __FILE__)

module SimpleCi
  
  WorkingDir = "#{ENV['HOME']}/simple_ci"

end

#modification to bunlers with_clean_env method.  makes sure that all env variables are cleared.
#required inorder to be able to 
#  Bundler.with_clean_env { system "bundle exec rake spec" }
BUNDLER_VARS = %w(BUNDLE_GEMFILE RUBYOPT BUNDLE_BIN_PATH)
module Bundler
  def self.with_clean_env &blk
    bundled_env = ENV.to_hash
    BUNDLER_VARS.each{ |var| ENV.delete(var) }
    yield
  ensure
    ENV.replace(bundled_env.to_hash)     
  end
end


# Initialize the rails application
SimpleCi::Application.initialize!
