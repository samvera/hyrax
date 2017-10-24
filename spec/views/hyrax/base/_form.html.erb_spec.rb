RSpec.describe 'hyrax/base/_form.html.erb', type: :view do
  let(:work) do
    stub_model(GenericWork, id: '456')
  end

  let(:change_set) do
    GenericWorkChangeSet.new(work)
  end
  let(:options_presenter) { double(select_options: []) }
  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  before do
    allow(Hyrax::AdminSetOptionsPresenter).to receive(:new).and_return(options_presenter)
    stub_template('hyrax/base/_form_progress.html.erb' => 'Progress')
    allow(work).to receive(:member_ids).and_return([1, 2])
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:change_set, change_set)
    allow(controller).to receive(:controller_name).and_return('batch_uploads')
    allow(controller).to receive(:action_name).and_return('new')
    allow(controller).to receive(:repository).and_return(Hyrax::GenericWorksController.new.repository)
    allow(controller).to receive(:blacklight_config).and_return(Hyrax::GenericWorksController.new.blacklight_config)
    allow(change_set).to receive(:collections_for_select).and_return([])
    allow(change_set).to receive(:permissions).and_return([])
  end

  context "for a new object" do
    let(:work) { GenericWork.new }

    context 'with batch_upload on' do
      before do
        allow(Flipflop).to receive(:batch_upload?).and_return(true)
      end
      it 'shows batch uploads' do
        expect(page).to have_link('Batch upload')
      end
    end
    context 'with batch_upload off' do
      before do
        allow(Flipflop).to receive(:batch_upload?).and_return(false)
      end
      it 'hides batch uploads' do
        expect(page).not_to have_link('Batch upload')
      end
    end
    context 'with browse-everything disabled (default)' do
      before do
        allow(Hyrax.config).to receive(:browse_everything?) { nil }
      end
      it "draws the page" do
        expect(page).to have_selector("form[action='/concern/generic_works'][data-param-key='generic_work']")
        expect(page).to have_link('Batch upload')
        # does not render the BE upload widget
        expect(page).not_to have_selector('button#browse-btn')

        # Draws the "Share" tab, with data for the javascript.
        expect(page).to have_selector('#share[data-param-key="generic_work"]')
      end
    end

    context 'with browse-everything enabled' do
      before do
        allow(Hyrax.config).to receive(:browse_everything?) { 'not nil' }
      end
      it 'renders the BE upload widget' do
        expect(page).to have_selector('button#browse-btn')
      end
    end

    describe 'uploading a folder' do
      it 'renders the add folder button' do
        expect(page).to have_content('Add folder...')
      end
    end
  end

  context "for a persisted object" do
    let(:work) { stub_model(GenericWork, id: '456') }

    before do
      # Add an error to the work
      work.errors.add :base, 'broken'
      work.errors.add :visibility, 'visibility_error'
      allow(change_set).to receive(:select_files).and_return([])
    end

    it "draws the page" do
      expect(page).to have_selector("form[action='/concern/generic_works/456']")
      expect(page).to have_selector("select#generic_work_resource_type", count: 1)
      expect(page).to have_selector("select#generic_work_thumbnail_id", count: 1)
      expect(page).to have_selector("select#generic_work_representative_id", count: 1)

      # It diplays form errors
      expect(page).to have_content("broken")
      expect(page).to have_content("visibility_error")
    end
  end
end
