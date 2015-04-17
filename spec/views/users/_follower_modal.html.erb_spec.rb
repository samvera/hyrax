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


describe 'users/_follower_modal.html.erb', :type => :view do

  let(:frank) { FactoryGirl.create(:user, display_name: "Frank") }
  before do
    assign :user, frank
    assign :followers, []
  end

  describe "when current user has no followers" do

    before do
      allow(controller).to receive(:current_user).and_return(frank)
    end

    it "should indicate the lack of followers for you" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_text "No one is following you." 
    end
  end

  describe "when another user has no followers" do 

    before do
      allow(controller).to receive(:current_user).and_return(stub_model(User))
    end

    it "should indicate the lack of followers for this user" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_text "No one is following this user." 
    end
  end

end