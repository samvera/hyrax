require 'spec_helper'

describe 'users/_notify_number.html.erb', type: :view do
  it "draws user list" do
    assign :notify_number, 8
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector("#notify_number", text: '8 unread notifications')
  end
end
