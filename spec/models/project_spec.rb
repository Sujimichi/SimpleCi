require 'spec_helper'

describe Project do

  before(:all) do 
    setup_simple_project
  end

  after(:all) do 
    destroy_simple_project
  end
  
  before(:each) do 

    @project = valid_project
    @act1 = valid_action
    @act2 = valid_action
    #@project.actions << [@act1, @act2]
    @project.reload
  end

  it 'should have many actions' do 
    @project.actions.should be_a(Array)
    @project.actions.should == [@act1, @act2]
  end


  describe "initial_setup" do 
    before(:each) do 
      @project_dir = "#{ENV['HOME']}/simple_ci/project_#{@project.id}"
      @project.stub!(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
    end

    it 'should create a project directory in the working_dir' do
      @project.stub!(:setup_commands => []) #just to skip the commands on this test
      @project.initial_setup
      dir(@project_dir).should be_present
    end
  
    it 'should clone the source project into the project dir' do 
      @project.stub!(:setup_commands => []) #just to skip the commands on this test
      @project.initial_setup
      dir("#{@project_dir}/simple_project").should be_present
      dir("#{@project_dir}/simple_project").should be_a_git_repo
    end

    it 'should run some setup commands' do 
      @project.initial_setup
      db_files = Dir.open("#{@project_dir}/simple_project/db").to_a
      db_files.should be_include("development.sqlite3")
    end

    it 'should set the repo dir attribute' do 
      @project.stub!(:setup_commands => []) #just to skip the commands on this test
      @project.initial_setup
      @project.repo_path.should == "simple_project"
    end

  end

  describe "updating from source repo" do 
    before(:each) do 
      setup_simple_project
      @project_dir = "#{ENV['HOME']}/simple_ci/project_#{@project.id}"
      @project.stub!(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
      @project.stub!(:setup_commands => [], :update_commands => []) #just to skip the commands on this test
      @project.initial_setup
      
      insert_commit_to_simple_project(:message => "added test file") do 
        `touch test_file.txt`
      end

    end

    it 'should pull changes into the project folder' do 
      Dir.open("#{@project_dir}/simple_project").to_a.should_not be_include("test_file.txt")
      @project.update_repo
      Dir.open("#{@project_dir}/simple_project").to_a.should be_include("test_file.txt")
    end

    it 'should return true if the repo was updated, otherwise false' do 
      @project.update_repo.should be_true
      @project.update_repo.should be_false
    end

  end

  describe "observing source repo" do 
    before(:each) do 
      setup_simple_project
      @project_dir = "#{ENV['HOME']}/simple_ci/project_#{@project.id}"
      @project.stub!(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
      @project.stub!(:setup_commands => [], :update_commands => []) #just to skip the commands on this test
      @project.stub!(:results => [Result.new, Result.new]) #do_work is called regardless of repo update if there are no results
      @project.initial_setup
    end

    it 'should update the repo but not call do_work if repo is unchanged' do 
      @project.should_not_receive(:do_work)
      @project.poll
    end

    it 'should update the repo and call do_work if repo is changed' do 
      insert_commit_to_simple_project(:message => "added test file") do 
        `touch test_file.txt`
      end
      @project.should_receive(:do_work)
      @project.poll
    end
    
  end

  describe "do work" do 
    before(:each) do 
      @project.stub!(:source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project", :repo_path => "simple_project")
      @project.stub!(:setup_commands => []) #just to skip the commands on this test
      @project.initial_setup    
    end

    it 'should call prepare on each action' do 
      @act1.should_receive(:prepare).once
      @act2.should_receive(:prepare).once
      Delayed::Job.stub!(:enqueue => false)


      @project.stub!(:actions => [@act1, @act2])
      @project.do_work
    end

    it 'should add a job to the worker queue' do 
      job = Class.new
      RunCommandJob.should_receive(:new).with(@act1.id).once.and_return(job)
      RunCommandJob.should_receive(:new).with(@act2.id).once.and_return(job)
      job.should_receive(:perform).twice
      @project.do_work
    end

  end


end
