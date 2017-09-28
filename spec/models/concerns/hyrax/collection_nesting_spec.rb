RSpec.describe Hyrax::CollectionNesting do
  describe 'including this module' do
    let(:klass) do
      Class.new do
        def update_index
          true
        end

        include Hyrax::CollectionNesting
        attr_accessor :id
      end
    end

    subject { klass.new.tap { |obj| obj.id = '123' } }

    it { is_expected.to callback(:update_nested_collection_relationship_indices).after(:update_index) }
    it { is_expected.to respond_to(:update_nested_collection_relationship_indices) }

    describe '#update_nested_collection_relationship_indices' do
      it 'will call Hyrax.config.nested_relationship_reindexer' do
        expect(Hyrax.config.nested_relationship_reindexer).to receive(:call).with(id: subject.id).and_call_original
        subject.update_nested_collection_relationship_indices
      end
    end
  end
end
