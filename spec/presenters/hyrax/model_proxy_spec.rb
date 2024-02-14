# frozen_string_literal: true

RSpec.describe Hyrax::ModelProxy do
  subject(:proxy)     { proxy_class.new(solr_document) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:model)         { GenericWork }

  let(:attributes) do
    { "id" => '888888',
      "has_model_ssim" => [model.to_s] }
  end

  let(:proxy_class) do
    Class.new do
      include Hyrax::ModelProxy

      attr_accessor :solr_document

      def initialize(solr_document)
        self.solr_document = solr_document
      end
    end
  end

  it { is_expected.to be_persisted }

  describe '#id' do
    it 'delegates to the solr document' do
      expect(proxy.id).to eq '888888'
    end
  end

  describe '#model_name' do
    it 'delegates to the has_model_ssim model' do
      expect(proxy.model_name).to eq model.model_name
    end
  end

  describe '#to_key' do
    it 'delegates to the solr document' do
      expect(proxy.to_key).to contain_exactly '888888'
    end
  end

  describe '#to_model' do
    it 'gives self' do
      expect(proxy.to_model).to eql proxy
    end
  end

  describe '#to_param' do
    it 'delegates to the solr document' do
      expect(proxy.to_param).to eq '888888'
    end
  end

  # NOTE: This attribute is assigned to work classes only in Dassie.
  describe '#valid_child_concerns', :active_fedora do
    it 'delegates to the has_model_ssim model' do
      expect(Hyrax::ChildTypes.for(parent: solr_document.hydra_model))
        .to contain_exactly(*model.valid_child_concerns)
    end
  end
end
