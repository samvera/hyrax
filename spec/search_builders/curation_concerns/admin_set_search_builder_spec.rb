require 'spec_helper'

describe CurationConcerns::AdminSetSearchBuilder do
  let(:processor_chain) { [:filter_models] }
  let(:context) { double('context') }
  let(:user) { double('user') }
  let(:solr_params) { { fq: [] } }

  subject { described_class.new(context, :read) }
  describe '#filter_models' do
    before { subject.filter_models(solr_params) }

    it 'adds AdminSet to query' do
      expect(solr_params[:fq].first).to include('{!field f=has_model_ssim}AdminSet')
    end
  end
end
