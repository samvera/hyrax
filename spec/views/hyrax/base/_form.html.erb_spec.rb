RSpec.describe 'hyrax/base/_form.html.erb', type: :view do
  let(:work) do
    stub_model(GenericWork, id: '456')
  end
  let(:ability) { double }

  let(:form) do
    Hyrax::GenericWorkForm.new(work, ability, controller)
  end
  let(:options_presenter) { double(select_options: []) }

  before do
    allow(Hyrax::AdminSetOptionsPresenter).to receive(:new).and_return(options_presenter)
    stub_template('hyrax/base/_form_progress.html.erb' => 'Progress')
    # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
    allow(work).to receive(:new_record?).and_return(true)
    allow(work).to receive(:member_ids).and_return([1, 2])
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
    allow(controller).to receive(:controller_name).and_return('batch_uploads')
    allow(controller).to receive(:action_name).and_return('new')
    allow(controller).to receive(:repository).and_return(Hyrax::GenericWorksController.new.repository)
    allow(controller).to receive(:blacklight_config).and_return(Hyrax::GenericWorksController.new.blacklight_config)

    allow(form).to receive(:permissions).and_return([])
    allow(form).to receive(:visibility).and_return('public')
    stub_template 'hyrax/base/_form_files.html.erb' => 'files'
  end

  context "for a new object" do
    let(:work) { GenericWork.new }

    context 'with batch_upload on' do
      before do
        allow(Flipflop).to receive(:batch_upload?).and_return(true)
        render
      end
      it 'shows batch uploads' do
        expect(rendered).to have_link('Batch upload')
        expect(rendered).to have_selector("form[action='/concern/generic_works'][data-param-key='generic_work']")
        # Draws the "Share" tab, with data for the javascript.
        expect(rendered).to have_selector('#share[data-param-key="generic_work"]')
      end
    end

    context 'with batch_upload off' do
      before do
        allow(Flipflop).to receive(:batch_upload?).and_return(false)
        render
      end
      it 'hides batch uploads' do
        expect(rendered).not_to have_link('Batch upload')
      end
    end
  end

  context "for a persisted object" do
    let(:work) { stub_model(GenericWork, id: '456') }

    before do
      # Add an error to the work
      work.errors.add :base, 'broken'
      work.errors.add :visibility, 'visibility_error'
      allow(form).to receive(:select_files).and_return([])
      render
    end

    it "draws the page" do
      expect(rendered).to have_selector("form[action='/concern/generic_works/456']")
      expect(rendered).to have_selector("select#generic_work_resource_type", count: 1)
      expect(rendered).to have_selector("select#generic_work_thumbnail_id", count: 1)
      expect(rendered).to have_selector("select#generic_work_representative_id", count: 1)

      # It diplays form errors
      expect(rendered).to have_content("broken")
      expect(rendered).to have_content("visibility_error")
    end
  end

  describe "tabs" do
    let(:work) { stub_model(GenericWork, id: '456') }

    before do
      allow(form).to receive(:select_files).and_return([])
    end

    context "wtth default tabs" do
      it 'renders the expected tabs' do
        render
        expect(rendered).to have_link('Descriptions')
        expect(rendered).to have_link('Files')
        expect(rendered).to have_link('Relationships')
        expect(rendered).to have_link('Sharing')
      end
    end

    context 'with non-default tabs' do
      let(:tab_order) { ['metadata', 'relationships', 'newtab'] }

      before do
        allow(view).to receive(:form_tabs_for).with(form: form).and_return(tab_order)
        allow(view).to receive(:t).and_call_original
        allow(view).to receive(:t).with('hyrax.works.form.tab.newtab').and_return('New Tab')
        stub_template 'hyrax/base/_form_newtab.html.erb' => 'NewTab Content'
      end

      it 'renders the expected tabs' do
        render
        expect(rendered).to have_link('Descriptions')
        expect(rendered).to have_link('Relationships')
        expect(rendered).to have_link('New Tab')
        expect(rendered).to have_link('Sharing')
        expect(rendered).not_to have_link('Files')
        expect(rendered).to match(/NewTab Content/)
      end
    end
  end
end
