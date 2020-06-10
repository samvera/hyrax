# frozen_string_literal: true
RSpec.describe Hyrax::CitationsBehaviors::Formatters::ChicagoFormatter do
  subject(:formatter) { described_class.new(:no_context) }

  let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(work.to_solr), :no_ability) }
  let(:work)      { build(:generic_work, title: ['<ScrIPt>prompt("Confirm Password")</sCRIpt>']) }

  it 'sanitizes input' do
    expect(formatter.format(presenter)).not_to include 'prompt'
  end
end
