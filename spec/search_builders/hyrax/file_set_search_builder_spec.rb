# frozen_string_literal: true
RSpec.describe Hyrax::FileSetSearchBuilder do
  let(:processor_chain) { [:filter_models] }
  let(:ability) { double('ability') }
  let(:context) { FakeSearchBuilderScope.new }
  let(:user) { double('user') }
  let(:solr_params) { Blacklight::Solr::Request.new({ fq: [] }) }

  subject { described_class.new(context) }

  describe '#filter_models' do
    before { subject.filter_models(solr_params) }

    it 'adds FileSet to query' do
      expect(solr_params[:fq].first).to include('{!terms f=has_model_ssim}FileSet')
    end
  end

  describe '#find_one' do
    before do
      allow(subject).to receive(:blacklight_params).and_return(id: '12345')
      subject.find_one(solr_params)
    end

    it 'adds id to query' do
      expect(solr_params[:fq].first).to include('{!raw f=id}12345')
    end
  end
end
