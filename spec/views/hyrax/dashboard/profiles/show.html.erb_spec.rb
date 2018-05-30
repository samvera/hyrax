RSpec.describe 'hyrax/dashboard/profiles/show.html.erb', type: :view do
  let(:join_date) { 1.day.ago }
  let(:user) { stub_model(User, user_key: 'mjg', created_at: join_date) }
  let(:ability) { double(current_user: stub_model(User, user_key: 'mjg')) }
  let(:presenter) { Hyrax::UserProfilePresenter.new(user, ability) }

  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).and_return(true)
    assign(:user, user)
    assign(:presenter, presenter)
  end

  context "with trophy" do
    let(:trophy_presenter) { Hyrax::TrophyPresenter.new(solr_document) }
    let(:solr_document) do
      SolrDocument.new(id: 'trophy_abc123',
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
      expect(page).to have_selector(".list-group-item > div#contributions.tab-pane")
      expect(page).to have_selector("#trophyrow_#{solr_document.id}")
    end
  end
end
