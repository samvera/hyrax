# frozen_string_literal: true
RSpec.describe 'hyrax/base/_form.html.erb', type: :view do
  let(:controller_action) { 'new' }
  let(:controller_class)  { Hyrax::MonographsController }
  let(:options_presenter) { double(select_options: []) }

  before do
    # mock the admin set options presenter to avoid hitting Solr
    allow(Hyrax::AdminSetOptionsPresenter).to receive(:new).and_return(options_presenter)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:curation_concern).and_return(work)
    assign(:form, form)
    allow(controller).to receive(:action_name).and_return(controller_action)
    allow(controller).to receive(:repository).and_return(controller_class.new.blacklight_config.repository)
    allow(controller).to receive(:blacklight_config).and_return(controller_class.new.blacklight_config)
    allow(controller).to receive(:controller_name).and_return('batch_uploads')

    allow(form).to receive(:permissions).and_return([])
    allow(form).to receive(:visibility).and_return('public')
    stub_template 'hyrax/base/_form_files.html.erb' => 'files'
    stub_template 'hyrax/base/_currently_shared.html.erb' => 'shared'
  end

  context 'with a change_set style form' do
    let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
    let(:work) { build(:monograph, title: 'comet in moominland') }

    context 'for a new object' do
      it 'renders a form' do
        render

        expect(rendered).to have_selector("form[action='/concern/monographs']")
      end

      context 'with batch_upload off' do
        before do
          allow(Flipflop).to receive(:batch_upload?).and_return(false)
        end

        it 'hides batch uploads' do
          render
          expect(rendered).not_to have_link('Batch upload', href: hyrax.new_batch_upload_path(payload_concern: 'GenericWork'))
        end
      end
    end

    context 'with an existing object' do
      let(:work) { FactoryBot.valkyrie_create(:monograph) }

      it 'renders a form' do
        render
        expect(rendered).to have_selector("form[action='/concern/monographs/#{work.id}']")
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

  context 'with a legacy GenericWork' do
    let(:work) { stub_model(GenericWork, id: '456') }
    let(:ability) { double }
    let(:form) do
      Hyrax::GenericWorkForm.new(work, ability, controller)
    rescue NameError
      GenericWorkForm.new(work)
    end

    before do
      stub_template('hyrax/base/_form_progress.html.erb' => 'Progress')
      # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
      allow(work).to receive(:new_record?).and_return(true)
      # using [1, 2] as member_ids for valkyrie failed because those are not valkyrie ids.
      # using ['1', '2'] also failed because the valkyrie created id's were not found in
      # Valkyrie::Persistence::Memory::MetadataAdapter#cache
      member_ids = Hyrax.config.use_valkyrie? ? [] : [1, 2]
      allow(work).to receive(:member_ids).and_return(member_ids)
      allow(controller).to receive(:controller_name).and_return('batch_uploads')
      allow(form).to receive(:permissions).and_return([])
      allow(form).to receive(:visibility).and_return('public')
      allow(form).to receive(:select_files).and_return([])
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
          expect(rendered).to have_link('Batch upload', href: hyrax.new_batch_upload_path(payload_concern: 'GenericWork'))
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
          expect(rendered).not_to have_link('Batch upload', href: hyrax.new_batch_upload_path(payload_concern: 'GenericWork'))
        end
      end
    end

    context "for a persisted object" do
      before do
        if Hyrax.config.use_valkyrie?
          # #update_valkyrie_work bases the errors on the form, not the work
          form.errors.add :base, 'broken'
          form.errors.add :visibility, 'visibility_error'
        else
          work.errors.add :base, 'broken'
          work.errors.add :visibility, 'visibility_error'
        end
        render
      end

      it "draws the page" do
        expect(rendered).to have_selector("form[action='/concern/generic_works/456']")
        expect(rendered).to have_selector("select#generic_work_resource_type", count: 1)
        unless Hyrax.config.use_valkyrie?
          # TODO: try to pass `member_ids` above with values so these two assertions apply
          expect(rendered).to have_selector("select#generic_work_thumbnail_id", count: 1)
          expect(rendered).to have_selector("select#generic_work_representative_id", count: 1)
        end
      end

      it 'does not display the form errors within the form' do
        # Form errors are displayed by the flash_msg
        expect(rendered).not_to have_content("broken")
        expect(rendered).not_to have_content("visibility_error")
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
