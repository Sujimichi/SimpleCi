require 'spec_helper'

describe Project do
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


  describe "do work" do 

    it 'should call run on each of the projects actions' do 
      @act1.should_receive(:run).once
      @act2.should_receive(:run).once
      @project.stub!(:actions => [@act1, @act2])
      @project.do_work
    end

  end

end
