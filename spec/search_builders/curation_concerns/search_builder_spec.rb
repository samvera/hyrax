require 'spec_helper'

describe CurationConcerns::SearchBuilder do
  let(:processor_chain) { [:filter_models] }
  let(:ability) { double('ability') }
  let(:context) { double('context') }
  let(:user) { double('user') }
  let(:solr_params) { { fq: [] } }

  subject { described_class.new(processor_chain, context) }

  describe '#only_file_sets' do
    before { subject.only_file_sets(solr_params) }

    it 'adds FileSet to query' do
      expect(solr_params[:fq].first).to include('{!raw f=has_model_ssim}FileSet')
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

  describe '#gated_discovery_filters' do
    before do
      allow(subject).to receive(:current_ability).and_return(ability)
      allow(ability).to receive(:current_user).and_return(user)
      allow(user).to receive(:groups).and_return(['admin'])
    end

    it 'does not filter results for admin users' do
      expect(subject.gated_discovery_filters).to eq([])
    end
  end

  describe '#discovery_permissions' do
    context 'when showing my works' do
      before { allow(subject).to receive(:blacklight_params).and_return(works: 'mine') }

      it 'limits query to edit permissions' do
        expect(subject.discovery_permissions).to eq(['edit'])
      end
    end
  end

  describe '#filter_models' do
    before { subject.filter_models(solr_params) }

    it 'limits query to collection and generic work' do
      expect(solr_params[:fq].first).to match(/{!raw f=has_model_ssim}GenericWork.*OR.*{!raw f=has_model_ssim}Collection/)
    end
  end
end
