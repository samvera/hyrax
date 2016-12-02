describe 'sufia/users/edit.html.erb', type: :view do
  let(:user) { stub_model(User, user_key: 'mjg') }

  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    assign(:user, user)
    assign(:trophies, [])
  end

  it "shows an ORCID field" do
    render
    expect(rendered).to match(/ORCID Profile/)
  end

  context "with trophy" do
    let(:solr_document) { SolrDocument.new(id: 'abc123', has_model_ssim: 'GenericWork', title_tesim: ['Title']) }
    before do
      assign(:trophies, [Sufia::TrophyPresenter.new(solr_document)])
      render
    end
    let(:page) { Capybara::Node::Simple.new(rendered) }

    it "has trophy" do
      expect(page).to have_selector("#remove_trophy_abc123")
    end
  end

  context 'with Zotero integration enabled' do
    before do
      allow(Sufia.config).to receive(:arkivo_api) { true }
    end

    it 'shows a Zotero label' do
      render
      expect(rendered).to match(/Zotero Profile/)
    end

    context 'with a userID already set on the user instance' do
      before do
        allow(user).to receive(:zotero_userid) { '12345' }
        render
      end

      it 'shows a link to the Zotero profile' do
        expect(rendered).to have_link("Connected!", href: "https://www.zotero.org/users/12345")
      end
    end

    context 'with no existing token' do
      before { render }

      it 'shows a Zotero OAuth button' do
        expect(rendered).to have_css('a#zotero')
      end
    end

    context 'with an existing token, in the production env' do
      before do
        allow(Rails.env).to receive(:production?) { true }
        render
      end

      it 'shows a Zotero OAuth button' do
        expect(rendered).to have_css('a#zotero')
      end
    end
  end

  context 'with Zotero integration disabled' do
    before do
      allow(Sufia.config).to receive(:arkivo_api) { false }
    end

    it 'hides a Zotero OAuth button' do
      render
      expect(subject).not_to have_css('a#zotero')
    end
  end
end
