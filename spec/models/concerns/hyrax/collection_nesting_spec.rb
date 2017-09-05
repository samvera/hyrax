RSpec.describe Hyrax::CollectionNesting do
  describe 'including this module' do
    let(:klass) do
      Class.new do
        def self.after_save(method_name)
          @after_save ||= []
          @after_save << method_name # rubocop:disable RSpec/InstanceVariable
        end

        include Hyrax::CollectionNesting
        attr_accessor :id
      end
    end

    it 'will register an after_save call to #update_nested_collection_relationship_indices' do
      expect(klass.instance_variable_get("@after_save")).to eq([:update_nested_collection_relationship_indices])
    end

    it 'will add the instance method of #update_nested_collection_relationship_indices' do
      expect(klass.new).to respond_to(:update_nested_collection_relationship_indices)
    end

    describe '#update_nested_collection_relationship_indices' do
      it 'will call Hyrax.config.nested_relationship_reindexer' do
        subject = klass.new
        subject.id = "123"
        expect(Hyrax.config.nested_relationship_reindexer).to receive(:call).with(id: subject.id).and_call_original
        subject.update_nested_collection_relationship_indices
      end
    end
  end
end
