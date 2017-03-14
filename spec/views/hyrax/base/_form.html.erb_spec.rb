describe 'hyrax/base/_form.html.erb', type: :view do
  let(:work) do
    stub_model(GenericWork, id: '456')
  end
  let(:ability) { double }

  let(:form) do
    Hyrax::GenericWorkForm.new(work, ability, controller)
  end

  before do
    stub_template('hyrax/base/_form_progress.html.erb' => 'Progress')
    allow(work).to receive(:member_ids).and_return([1, 2])
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
    allow(controller).to receive(:controller_name).and_return('batch_uploads')
    allow(controller).to receive(:action_name).and_return('new')
    allow(controller).to receive(:repository).and_return(Hyrax::GenericWorksController.new.repository)
    allow(controller).to receive(:blacklight_config).and_return(Hyrax::GenericWorksController.new.blacklight_config)
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  context "for a new object" do
    let(:work) { GenericWork.new }
    context 'with browse-everything disabled (default)' do
      before do
        allow(Hyrax.config).to receive(:browse_everything?) { nil }
      end
      it "draws the page" do
        expect(page).to have_selector("form[action='/concern/generic_works']")
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
      context 'with Chrome' do
        before { allow(view).to receive(:browser_supports_directory_upload?) { true } }
        it 'renders the add folder button' do
          expect(page).to have_content('Add folder...')
        end
      end
      context 'with a non-Chrome browser' do
        before { allow(view).to receive(:browser_supports_directory_upload?) { false } }
        it 'does not render the add folder button' do
          expect(page).not_to have_content('Add folder...')
        end
      end
    end
  end

  context "for a persisted object" do
    let(:work) { stub_model(GenericWork, id: '456') }

    before do
      # Add an error to the work
      work.errors.add :base, 'broken'
    end

    it "draws the page" do
      expect(page).to have_selector("form[action='/concern/generic_works/456']")
      expect(page).to have_selector("select#generic_work_resource_type", count: 1)
      expect(page).to have_selector("select#generic_work_thumbnail_id", count: 1)
      expect(page).to have_selector("select#generic_work_representative_id", count: 1)

      # It diplays form errors
      expect(page).to have_content("broken")
    end
  end
end
