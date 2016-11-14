describe '/_toolbar.html.erb', type: :view do
  let(:presenter) { instance_double(Sufia::SelectTypeListPresenter, many?: false, first_model: GenericWork) }
  before do
    allow(view).to receive(:create_work_presenter).and_return(presenter)
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

  context 'with an admin user' do
    before do
      allow(view).to receive(:can?).with(:read, :admin_dashboard).and_return(true)
    end

    it 'shows the admin menu' do
      render
      expect(rendered).to have_link 'Admin', href: sufia.admin_path
    end
  end

  it 'has dashboard links' do
    render
    expect(rendered).to have_link 'My Dashboard', href: sufia.dashboard_index_path
    expect(rendered).to have_link 'Transfers', href: sufia.transfers_path
    expect(rendered).to have_link 'Highlights', href: sufia.dashboard_highlights_path
    expect(rendered).to have_link 'Shares', href: sufia.dashboard_shares_path
  end

  describe "New Work link" do
    context "when the user can create multiple work types" do
      let(:presenter) { instance_double(Sufia::SelectTypeListPresenter, many?: true) }
      it "has a link to upload" do
        render
        expect(rendered).to have_selector 'a[data-toggle="modal"][data-target="#worktypes-to-create"]'
        expect(rendered).to have_link('New Work', href: '#')
      end
    end

    context "when the user can create GenericWorks" do
      it "has a link to upload" do
        render
        expect(rendered).to have_link('New Work', href: new_curation_concerns_generic_work_path)
      end
    end

    context "when the user can't create any work types" do
      before do
        allow(view).to receive(:can_ever_create_works?).and_return(false)
      end
      it "does not have a link to upload" do
        render
        expect(rendered).not_to have_link('New Work')
      end
    end
  end

  describe "New Collection link" do
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
