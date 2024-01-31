# frozen_string_literal: true

# Hyrax::BatchUploadsController's form class is Hyrax::Forms::BatchUploadForm, which inherits from
#   Hyrax::Forms::WorkForm that utilizes app/services/hydra_editor/field_metadata_service.rb.
#   That service calls #reflect_on_association on the Work class. This is an ActiveFedora-specific
#   method that doesn't translate to Valkyrie Work behavior.
RSpec.describe 'hyrax/batch_uploads/_form.html.erb', :active_fedora, type: :view do
  let(:work) { GenericWork.new }
  let(:ability) { double('ability', current_user: user) }
  let(:controller_class) { Hyrax::BatchUploadsController }
  let(:options_presenter) { double(select_options: []) }
  let(:form) { Hyrax::Forms::BatchUploadForm.new(work, ability, controller) }
  let(:user) { stub_model(User) }
  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  before do
    # Tell rspec where to find form_* partials
    view.lookup_context.prefixes << 'hyrax/base'
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(controller).to receive(:repository).and_return(controller_class.new.blacklight_config.repository)
    allow(controller).to receive(:blacklight_config).and_return(controller_class.new.blacklight_config)
    # mock the admin set options presenter to avoid hitting Solr
    allow(Hyrax::AdminSetOptionsPresenter).to receive(:new).and_return(options_presenter)
    assign(:form, form)
  end

  it "draws the page" do
    expect(page).to have_selector("form[action='/batch_uploads']")
    expect(page).to have_selector("form[action='/batch_uploads'][data-behavior='work-form']")
    expect(page).to have_selector("form[action='/batch_uploads'][data-param-key='batch_upload_item']")
    # No title, because it's captured per file (e.g. Display label)
    expect(page).not_to have_selector("input#generic_work_title")
    expect(view.content_for(:files_tab)).to have_link("New Work", href: "/concern/generic_works/new")
  end

  describe 'tabs' do
    it 'shows form tabs' do
      expect(page).to have_link('Files')
      expect(page).to have_link('Descriptions')
      expect(page).to have_link('Relationships')
      expect(page).to have_link('Sharing')
    end
  end
end
