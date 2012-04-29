require 'spec_helper'

def ready_project_dir args = {:fast => false}
  if args[:fast].eql?(true)
    @project.stub!(:setup_commands => [])  #just to skip the commands on this test
  else
    @project.stub!(:setup_commands => Project.new.setup_commands) #replace stubbed attr with original (which is got from another new obj)
  end
  @project.initial_setup
end

describe Action do
  before(:all) do 
    #FileUtils.rm_rf("#{ENV['HOME']}/simple_ci/")
    setup_simple_project
  end

  after(:all) do 
    destroy_simple_project
  end

  before(:each) do 
    @project = valid_project(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
    @action = valid_action #will also create @project
  end

  describe "prepare" do 
    before(:each) do 
      ready_project_dir(:fast => true)
      @action_dir = "#{ENV['HOME']}/simple_ci/action_#{@action.id}"
    end

    it 'should prepare a temp dir' do 
      @action.prepare
      dir(@action_dir).should be_present
    end

    it 'should reset temp dir if present' do 
      @action.prepare
      Dir.chdir(@action_dir) #exists from prev test
      File.open("foo.txt","w"){|file| file << "this is a file"} #put file in dir
      Dir.open(@action_dir).to_a.should == ['.', 'simple_project', '..', 'foo.txt']
      @action.prepare
      Dir.open(@action_dir).to_a.should == ['.', 'simple_project', '..'] #dir should now be reset
    end

    it 'should copy the project into the actions dir' do
      @action.prepare
      dir("#{@action_dir}/simple_project").should be_present
      dir("#{@action_dir}/simple_project").should be_a_git_repo
    end

    it 'should be in a state where commands can be run' do
      ready_project_dir(:fast => false)
      @action.prepare
      
      Dir.chdir("#{@action_dir}/simple_project")
      r = `rake spec`
      r.should be_include("31 examples, 1 failure, 1 pending") #the result of the specs from the simple_project
    end
    




  end
end
