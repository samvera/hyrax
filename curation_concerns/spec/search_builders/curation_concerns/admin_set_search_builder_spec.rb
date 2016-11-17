require 'spec_helper'

describe CurationConcerns::AdminSetSearchBuilder do
  let(:context) { double('context') }
  let(:solr_params) { { fq: [] } }

  let(:builder) { described_class.new(context, :read) }
  describe '#filter_models' do
    before { builder.filter_models(solr_params) }

    it 'adds AdminSet to query' do
      expect(solr_params[:fq].first).to include('{!terms f=has_model_ssim}AdminSet')
    end
  end

  describe ".default_processor_chain" do
    subject { described_class.default_processor_chain }
    it { is_expected.to include :filter_models }
  end
end
