require 'spec_helper'

describe 'users/_notify_number.html.erb', :type => :view do

  it "should draw user list" do
    assign :notify_number, 8
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector("span#notify_number.overlay", text: ' 8')
  end

end

