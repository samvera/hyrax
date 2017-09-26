RSpec.describe Hyrax::CollectionNesting do
  describe 'including this module' do
    let(:klass) do
      Class.new do
        def self.after_update_index(method_name)
          @after_update_index ||= []
          @after_update_index << method_name # rubocop:disable RSpec/InstanceVariable
        end

        def self.define_model_callbacks(method_name, only:)
          @define_model_callbacks ||= []
          @define_model_callbacks << [method_name, only]  # rubocop:disable RSpec/InstanceVariable
        end

        include Hyrax::CollectionNesting
        attr_accessor :id
      end
    end

    it 'will register an after_update_index call to #update_nested_collection_relationship_indices' do
      expect(klass.instance_variable_get("@after_update_index")).to eq([:update_nested_collection_relationship_indices])
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
