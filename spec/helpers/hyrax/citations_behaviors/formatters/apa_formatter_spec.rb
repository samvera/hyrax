# frozen_string_literal: true
RSpec.describe Hyrax::CitationsBehaviors::Formatters::ApaFormatter do
  subject(:formatter) { described_class.new(:no_context) }

  let(:solr_document) do
    if work.is_a? ActiveFedora::Base
      SolrDocument.new(work.to_solr)
    else
      SolrDocument.new(GenericWorkIndexer.new(resource: work).to_solr)
    end
  end
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, :no_ability) }
  let(:work)      { build(:generic_work, title: ['Title'], creator: []) }

  it 'formats citations without creators' do
    expect(formatter.format(presenter)).to eq("<i class=\"citation-title\">Title.</i> ")
  end
end
