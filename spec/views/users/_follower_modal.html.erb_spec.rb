require 'spec_helper'

describe 'users/_follower_modal.html.erb', :type => :view do
  let(:user) { FactoryGirl.create(:user, display_name: "Frank") }

  before do
    assign :followers, [user]
  end

  it "should draw user list" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link "Frank", href: "/users/#{user.to_param}" 
  end

end


