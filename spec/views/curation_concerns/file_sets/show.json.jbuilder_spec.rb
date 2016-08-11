require 'spec_helper'

describe 'curation_concerns/file_sets/show.json.jbuilder' do
  let(:file_set) { create(:file_set) }
  let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_doc, nil) }

  before do
    assign(:presenter, presenter)
    render
  end

  it "renders json of the curation_concern" do
    json = JSON.parse(rendered)
    expect(json['id']).to eq file_set.id
    expect(json['title']).to eq file_set.title
    expect(json).to have_key('label')
    expect(json).to have_key('description')
    expect(json).to have_key('creator')
  end
end
