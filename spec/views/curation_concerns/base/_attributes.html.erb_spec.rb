require 'spec_helper'

describe 'curation_concerns/base/_attributes.html.erb' do
  let(:creator)     { 'Bilbo' }
  let(:contributor) { 'Frodo' }
  let(:subject)     { 'history' }
  let(:description) { ['Lorem ipsum < lorem ipsum. http://my.link.com'] }

  let(:solr_document) { SolrDocument.new(subject_tesim: subject,
                                         contributor_tesim: contributor,
                                         creator_tesim: creator,
                                         description_tesim: description) }
  let(:ability) { nil }
  let(:presenter) do
    CurationConcerns::WorkShowPresenter.new(solr_document, ability)
  end
  let(:doc) { Nokogiri::HTML(rendered) }

  before do
    allow(view).to receive(:dom_class) { '' }

    render 'curation_concerns/base/attributes', presenter: presenter
  end

  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_link(creator, href: search_catalog_path(search_field: 'creator', q: creator))
    expect(rendered).to have_link(contributor, href: search_catalog_path(search_field: 'contributor', q: contributor))
    expect(rendered).to have_link(subject, href: search_catalog_path(search_field: 'subject', q: subject))
  end
  it 'shows links in the description' do
    a1 = doc.xpath("//li[@class='attribute description']/span/a").text
    expect(a1).to start_with 'http://my.link.com'
  end
end
