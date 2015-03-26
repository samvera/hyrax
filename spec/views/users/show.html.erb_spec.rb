require 'spec_helper'

describe 'users/show.html.erb', :type => :view do

  let(:join_date) { 5.days.ago }
  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(stub_model(User, user_key: 'mjg'))
    assign(:user, stub_model(User, user_key: 'cam156', created_at: join_date))
    assign(:followers, [])
    assign(:following, [])
    assign(:trophies, [])
    assign(:events, [])
  end

  it "should draw 3 tabs" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector("ul#myTab.nav.nav-tabs > li > a[href='#contributions']")
    expect(page).to have_selector("ul#myTab.nav.nav-tabs > li > a[href='#profile']")
    expect(page).to have_selector("ul#myTab.nav.nav-tabs > li > a[href='#activity_log']")
    expect(page).to have_selector(".tab-content > div#contributions.tab-pane")
    expect(page).to have_selector(".tab-content > div#profile.tab-pane")
    expect(page).to have_selector(".tab-content > div#activity_log.tab-pane")
  end

  it "should have the vitals" do
    render
    expect(rendered).to match /Joined on #{join_date.strftime("%b %d, %Y")}/
  end

  context "with trophy" do

    let(:generic_file) { stub_model(GenericFile, title: ["Fake object"], id: "abc123") }
    before do
      allow(view).to receive(:search_session).and_return({})
      allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(view).to receive(:current_search_session).and_return(nil)
      assign(:trophies, [generic_file])
    end

    it "should have trophy" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_selector(".tab-content > div#contributions.tab-pane")
      expect(page).to have_selector("#trophyrow_#{generic_file.id}")

    end
  end
end
