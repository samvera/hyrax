# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/edit.html.erb', type: :view do
  let(:ability) { double }
  let(:doc) do
    {
      "has_model_ssim" => ["FileSet"],
      :id => "123",
      "title_tesim" => ["My Title"]
    }
  end
  let(:solr_doc) { SolrDocument.new(doc) }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_doc, ability) }
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }
  let(:file_set) { double('Hyrax::FileSet') }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:download, solr_doc).and_return(true)
    assign(:presenter, presenter)
    assign(:parent_presenter, parent_presenter)
    allow(presenter).to receive(:parent).and_return(parent_presenter)
    allow(presenter).to receive(:parent_presenter).and_return(parent_presenter)
    assign(:document, solr_doc)
    stub_template 'hyrax/file_sets/_form.html.erb' => 'Some form'
    stub_template 'hyrax/file_sets/_permission.html.erb' => 'Permission form'
    stub_template 'hyrax/file_sets/_versioning.html.erb' => 'Versioning form'
    allow_any_instance_of(ActionView::Base).to receive(:curation_concern).and_return(file_set)
  end

  context 'with an adapter that allows for file versioning' do
    before do
      assign(:version_list, double('Hyrax::VersionListPresenter', supports_multiple_versions?: true))
      render
    end

    it 'displays a versioning tab' do
      expect(rendered).to have_selector('#edit_versioning_link', text: 'Versions')
    end
  end
  context 'with an adapter that does not allow for file versioning' do
    before do
      assign(:version_list, double('Hyrax::VersionListPresenter', supports_multiple_versions?: false))
      render
    end

    it 'does not display a versioning tab' do
      expect(rendered).not_to have_selector('#edit_versioning_link', text: 'Versions')
    end
  end
end
