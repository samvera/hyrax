require 'spec_helper'

describe 'my/_index_partials/_list_works.html.erb' do
  let(:work_title) { 'Work Title' }
  let(:coll_title) { 'Collection Title' }
  let(:collection) { FactoryGirl.build(:collection, id: '3197z497t', title: coll_title) }
  let!(:work) { FactoryGirl.build(:work, id: '3197z511f', title: [work_title]) }
  let(:doc) { SolrDocument.new(work.to_solr) }

  let(:config) { My::FilesController.new.blacklight_config }
  let(:members) { [SolrDocument.new(collection.to_solr)] }

  before do
    expect(Sufia::CollectionMemberService).to receive(:run).with(doc).and_return(members)
    allow(view).to receive(:blacklight_config) { config }
    view.lookup_context.prefixes = %w(collections)
    assign(:collection, collection)
    render 'my/_index_partials/list_works', document: doc
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{work.id}")
    expect(rendered).to have_link work_title, href: curation_concerns_generic_work_path(work)
    expect(rendered).to have_link 'Edit Work', href: edit_curation_concerns_generic_work_path(work)
    expect(rendered).to have_link 'Delete Work', href: curation_concerns_generic_work_path(work)
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_link coll_title, href: collections.collection_path(collection)
  end
end
