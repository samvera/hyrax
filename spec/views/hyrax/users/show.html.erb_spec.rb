describe 'hyrax/users/show.html.erb', type: :view do
  let(:join_date) { 5.days.ago }
  let(:ability) { double(current_user: current_user) }
  let(:user) { stub_model(User, user_key: 'cam156', created_at: join_date) }
  let(:presenter) { Hyrax::UserProfilePresenter.new(user, ability) }
  let(:current_user) { stub_model(User, user_key: 'mjg') }

  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(current_user)
    allow(view).to receive(:can?).and_return(true)
    assign(:user, user)
    assign(:presenter, presenter)
  end

  it "draws 3 tabs" do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector("ul#myTab.nav.nav-tabs > li > a[href='#contributions']")
    expect(page).to have_selector("ul#myTab.nav.nav-tabs > li > a[href='#activity_log']")
    expect(page).to have_selector(".tab-content > div#contributions.tab-pane")
    expect(page).to have_selector(".tab-content > div#activity_log.tab-pane")
  end

  it "has the vitals" do
    render
    expect(rendered).to match(/Joined on #{join_date.strftime("%b %d, %Y")}/)
  end

  context "with trophy" do
    let(:trophy_presenter) { Hyrax::TrophyPresenter.new(solr_document) }
    let(:solr_document) do
      SolrDocument.new(id: 'abc123',
                       has_model_ssim: 'GenericWork',
                       thumbnail_path_ss: '/foo/bar.png')
    end

    before do
      allow(view).to receive(:search_session).and_return({})
      allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      allow(view).to receive(:current_search_session).and_return(nil)
      allow(presenter).to receive(:trophies).and_return([trophy_presenter])
    end

    it "has trophy" do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_selector(".tab-content > div#contributions.tab-pane")
      expect(page).to have_selector("#trophyrow_#{solr_document.id}")
    end
  end
end
