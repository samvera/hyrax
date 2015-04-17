require 'spec_helper'

describe 'users/_following_modal.html.erb', :type => :view do
  let(:user) { FactoryGirl.create(:user, display_name: "Frank") }

  before do
    assign :following, [user]
  end

  it "should draw user list" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_link "Frank", href: "/users/#{user.to_param}" 
  end

end


describe 'users/_following_modal.html.erb', :type => :view do

  let(:frank) { FactoryGirl.create(:user, display_name: "Frank") }
  before do
    assign :user, frank
    assign :following, []
  end

  describe "when current user is not following anyone" do

    before do
      allow(controller).to receive(:current_user).and_return(frank)
    end

    it "should indicate that you are not following anyone" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_text "You are not following anyone." 
    end
  end

  describe "when another user is not following anyone" do 

    before do
      allow(controller).to receive(:current_user).and_return(stub_model(User))
    end

    it "should indicate the user is not following anyone" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_text "This user is not following anyone." 
    end
  end

end
