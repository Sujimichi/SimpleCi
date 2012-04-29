require 'spec_helper'

describe "projects/index" do
  before(:each) do
    assign(:projects, [
      stub_model(Project,
        :name => "Name",
        :source_path => "Source Path",
        :branch => "Branch"
      ),
      stub_model(Project,
        :name => "Name",
        :source_path => "Source Path",
        :branch => "Branch"
      )
    ])
  end

  it "renders a list of projects" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Source Path".to_s, :count => 2
    assert_select "tr>td", :text => "Branch".to_s, :count => 2
  end
end
