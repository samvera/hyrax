require "spec_helper"

RSpec.describe 'PowerConverter' do
  context '#convert_to_sipity_entity' do
    subject { PowerConverter.convert(object, to: :sipity_entity) }

    context "with a Sipity::Entity" do
      let(:object) { Sipity::Entity.new }

      it { is_expected.to eq object }
    end

    context "with a Sipity::Comment" do
      let(:object) { Sipity::Comment.new(entity: entity) }
      let(:entity) { Sipity::Entity.new }

      it { is_expected.to eq entity }
    end

    context "with a SolrDocument" do
      let(:object) { SolrDocument.new(id: '9999', Valkyrie::Persistence::Solr::Queries::MODEL => ["GenericWork"]) }
      let(:workflow_state) { create(:workflow_state) }
      let!(:entity) do
        Sipity::Entity.create(proxy_for_global_id: 'gid://internal/GenericWork/9999',
                              workflow_state: workflow_state,
                              workflow: workflow_state.workflow)
      end

      it { is_expected.to eq entity }
    end

    context 'a Models::Work (because it will be processed)' do
      let(:object) { build(:work) }

      # This is poking knowledge over into the inner workings of Models::Work
      # but is a reasonable place to understand this.
      it 'will raise an exception if one has not been assigned' do
        expect { subject }.to raise_error RuntimeError, "Can't create an entity until the model has been persisted"
      end
    end

    context 'with an object that responds to processing_entity' do
      let(:object) { double(to_sipity_entity: :processing_entity) }

      it { is_expected.to eq :processing_entity }
    end

    context 'with an invalid object' do
      let(:object) { double }

      it 'will raise an error if it cannot convert' do
         expect { subject }.to raise_error PowerConverter::ConversionError
       end
    end
  end
end
