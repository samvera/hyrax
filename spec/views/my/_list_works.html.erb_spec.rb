require 'spec_helper'

describe 'my/_index_partials/_list_works.html.erb' do
  let(:id) { "3197z511f" }
  let(:work_data) do
    {
      id: id,
      "has_model_ssim" => ["GenericWork"],
      "title_tesim" => ["Work Title"]
    }
  end

  let(:doc) { SolrDocument.new(work_data) }
  let(:collection) { mock_model(Collection) }
  let(:config) { My::WorksController.blacklight_config }
  let(:user) { FactoryGirl.build(:user) }
  let(:presenter) { Sufia::WorkShowPresenter.new(doc, nil) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    allow(view).to receive(:render_collection_links).with(doc).and_return("<a href=\"collection/1\">Collection Title</a>".html_safe)
    allow(view).to receive(:render_visibility_link).with(doc).and_return("<a class=\"visibility-link\">Private</a>".html_safe)
    allow(view).to receive(:blacklight_config) { config }
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    view.lookup_context.prefixes = %w(collections)

    # Required by hydra-collections-7.0.0/app/views/collections/_button_remove_from_collection.html.erb
    # TODO: when we upgrade to hydra-collections 8, we can remove this
    assign(:collection, collection)

    # Required by app/views/collections/_work_action_menu.html.erb
    assign(:user, user)
    render 'my/_index_partials/list_works', document: doc, presenter: presenter
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{id}")
    expect(rendered).to have_link 'Work Title', href: curation_concerns_generic_work_path(id)
    expect(rendered).to have_link 'Edit Work', href: edit_curation_concerns_generic_work_path(id)
    expect(rendered).to have_link 'Delete Work', href: curation_concerns_generic_work_path(id)
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_link 'Collection Title', href: 'collection/1'
    expect(rendered).to have_link 'Highlight Work on Profile'
  end
end
