require 'spec_helper'

describe Action do
  before(:each) do 
    @action = valid_action #will also create @project
    @project.stub!(:source_path => "~/coding/rails/some_project/")
  end

  before(:all) do 
    setup_simple_project
  end

  after(:all) do 
    destroy_simple_project
  end


  describe "run" do 
    before(:each) do 
      @action.run
      @action_dir = "#{ENV['HOME']}/simple_ci/action_#{@action.id}"
    end

    it 'should prepare a temp dir' do 
      begin
        dir = Dir.open(@action_dir)
      rescue
        raise "it should have created dir: #{@action_dir}"
      end
    end

    it 'should git clone the project source into the temp folder' 



  end
end
