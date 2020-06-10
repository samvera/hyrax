# frozen_string_literal: true
RSpec.describe Hyrax::CitationsBehaviors::Formatters::ApaFormatter do
  subject(:formatter) { described_class.new(:no_context) }

  let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(work.to_solr), :no_ability) }
  let(:work)      { build(:generic_work, title: ['Title'], creator: []) }

  it 'formats citations without creators' do
    expect(formatter.format(presenter)).to eq("<i class=\"citation-title\">Title.</i> ")
  end
end
