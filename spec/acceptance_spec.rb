require 'spec_helper'

describe Project do

  before(:all) do 
    setup_simple_project
  end

  after(:all) do 
    destroy_simple_project
  end

  before(:each) do 
  end


  describe "simple usage" do

    before(:each) do 
      @project = Project.create!(:name => "project whatever", :source_path => "#{ENV['HOME']}/simple_ci_testing/simple_project")
    end
    
    it 'should initialize a project, add and run an rspec action and store the result' do 
      @project.initial_setup

      Action.create!(:command => "bundle exec rspec", :project => @project)
      @project.reload.actions.size.should == 1

      @project.poll

      @project.reload.results.size.should == 1
      Result.first.commit_id.should == "dd482a81c13a07b1c233c4d70e9e7c18cb7c2a21"
      Result.first.data.should be_include("31 examples, 1 failure, 1 pending")

    end


    it 'should run the same action and get dif results once the app has been changed' do 
      @project.initial_setup

      Action.create!(:command => "bundle exec rspec", :project => @project)
      @project.reload.actions.size.should == 1

      @project.poll

      insert_commit_to_simple_project(:message => "adding another failing spec") do 
        File.open("spec/models/another_spec.rb",'w'){|file| file.write(FileData.simple_failing_spec) }
      end

      @project.poll

      Result.all.size.should == 2
      Result.first.data.should be_include("31 examples, 1 failure, 1 pending")
      Result.last.data.should be_include("32 examples, 2 failures, 1 pending")
    end


  end



end

class FileData

  def self.simple_failing_spec

<<EOF
require 'spec_helper'
describe "something" do 
  it 'should have a test which fails' do 
    false.should be_true
  end
end
EOF

  end


end
