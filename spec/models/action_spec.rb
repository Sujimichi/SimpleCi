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
    Rails.cache.clear
    @project = valid_project(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
    @action = valid_action #will also create @project
    @action_dir = "#{ENV['HOME']}/simple_ci/action_#{@action.id}"
  end

  describe "prepare" do 
    before(:each) do 
      ready_project_dir(:fast => true)
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

    it 'should be in a state where rake commands can be run' do
      ready_project_dir(:fast => false)
      @action.prepare
      
      Dir.chdir("#{@action_dir}/simple_project")
      r = `rake spec`
      r.should be_include("31 examples, 1 failure, 1 pending") #the result of the specs from the simple_project
    end
    
  end


  describe "run_command" do 
    before(:each) do 
      ready_project_dir(:fast => true)
      @action.prepare
    end

    it 'should run the actions command in the project directory' do 
      
      Dir.open("#{@action_dir}/simple_project").to_a.should_not be_include("test_file.txt")
      @action.stub!(:command => "touch test_file.txt")

      @action.run_command
      Dir.open("#{@action_dir}/simple_project").to_a.should be_include("test_file.txt")
    end

    it 'should store the result as a Result' do 
      Result.count.should == 0
      @action.stub!(:command => "ls")
      @action.run_command
      Result.first.data.split("\n").should == %w[app  config  config.ru  db  doc  Gemfile  Gemfile.lock  lib  public  Rakefile  README.rdoc  script  spec  test  vendor]
      
    end

    it 'should record the commit id with the result' do 
      @action.stub!(:command => "ls")
      @action.run_command

      Result.first.commit_id.should == "dd482a81c13a07b1c233c4d70e9e7c18cb7c2a21"
    end

  end

end
