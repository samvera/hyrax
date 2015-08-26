require 'spec_helper'

describe 'curation_concerns/base/_attributes.html.erb' do
  let(:creator)     { 'Bilbo' }
  let(:contributor) { 'Frodo' }
  let(:subject)     { 'history' }

  let(:solr_document) { SolrDocument.new(subject_tesim: subject,
                                         contributor_tesim: contributor,
                                         creator_tesim: creator) }
  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::GenericWorkShowPresenter.new(solr_document, ability)
  end

  before do
    allow(view).to receive(:dom_class) { '' }

    assign(:presenter, presenter)
    render
  end

  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_link(creator, href: catalog_index_path(search_field: 'creator', q: creator))
    expect(rendered).to have_link(contributor, href: catalog_index_path(search_field: 'contributor', q: contributor))
    expect(rendered).to have_link(subject, href: catalog_index_path(search_field: 'subject', q: subject))
  end
end
