describe '/_toolbar.html.erb', type: :view do
  before do
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(stub_model(User, user_key: 'userX'))
    allow(view).to receive(:can?).and_call_original
  end

  context 'with an anonymous user' do
    before do
      allow(view).to receive(:user_signed_in?).and_return(false)
    end

    it 'shows no toolbar links' do
      render
      expect(rendered).not_to have_link 'Admin'
      expect(rendered).not_to have_link 'Dashboard'
      expect(rendered).not_to have_link 'Works'
      expect(rendered).not_to have_link 'Collections'
    end
  end

  it 'has dashboard links' do
    render
    expect(rendered).to have_link 'My Dashboard', sufia.dashboard_index_path
    expect(rendered).to have_link 'Transfers', sufia.transfers_path
    expect(rendered).to have_link 'Highlights', sufia.dashboard_highlights_path
    expect(rendered).to have_link 'Shares', sufia.dashboard_shares_path
  end

  describe "New Work button" do
    context "when the user can create file sets" do
      it "has a link to upload" do
        allow(view).to receive(:can?).with(:create, GenericWork).and_return(true)
        render
        expect(rendered).to have_link('New Work', href: sufia.new_curation_concerns_generic_work_path)
      end
    end

    context "when the user can't create file sets" do
      it "does not have a link to upload" do
        allow(view).to receive(:can?).with(:create, GenericWork).and_return(false)
        render
        expect(rendered).not_to have_link('New Work')
      end
    end
  end

  describe "New Collection button" do
    context "when the user can create collections" do
      it "has a link to upload" do
        allow(view).to receive(:can?).with(:create, Collection).and_return(true)
        render
        expect(rendered).to have_link('New Collection', href: new_collection_path)
      end
    end

    context "when the user can't create file sets" do
      it "does not have a link to upload" do
        allow(view).to receive(:can?).with(:create, Collection).and_return(false)
        render
        expect(rendered).not_to have_link('New Collection')
      end
    end
  end
end
