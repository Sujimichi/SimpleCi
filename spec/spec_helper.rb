# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
end

def valid_project attrs = {}
  name = Project.all.last.name unless Project.all.empty?
  name ||= "test project 0"
  obj_attrs = {:name => name.next}.merge(attrs)
  Project.create!(obj_attrs)
end

def valid_action attrs = {}
  @project ||= valid_project
  obj_attrs = {:project_id => @project.id}.merge(attrs)
  Action.create!(obj_attrs)
end

def setup_simple_project
  file = "#{Rails.root}/spec/simple_project.zip"
  path = "#{ENV['HOME']}/simple_ci_testing"
  `mkdir #{path}` #make dir if not already present
  `unzip -o #{file} -d #{path}` #unpack zip of sample project folder into dir.
end

def destroy_simple_project
  path = "#{ENV['HOME']}/simple_ci_testing"
  `rm -rf #{path}`
end


def dir path
  DirData.new(path)
end

class DirData
  def initialize path
    @path = path
  end

  def is_present?
    r= false
    begin
      Dir.open(@path)
      r = true
    rescue
      #raise "it should have created dir: #{@action_dir}"
    end
    r
  end
  alias present? is_present?

  def git_repo?
    return false unless present?
    Dir.chdir(@path)
    s = `git status`
    s.downcase.include?("on branch")
  end

end
