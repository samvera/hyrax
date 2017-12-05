# frozen_string_literals: true

RSpec.describe Hyrax::ChangeSetPersister, type: :model do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

  describe 'saving' do
    let(:resource) { GenericWork.new }
    let(:change_set) { Hyrax::WorkChangeSet.new(resource) }
    let(:resource_two) { GenericWork.new }
    let(:change_set_two) { Hyrax::WorkChangeSet.new(resource_two) }

    it 'can save a resource' do
      expect { change_set_persister.save(change_set: change_set) }.to change { query_service.find_all_of_model(model: resource.class).count }.by(1)
    end

    it 'returns the resource' do
      expect(change_set_persister.save(change_set: change_set).class).to eq(resource.class)
    end

    it 'can save multiple resources' do
      expect { change_set_persister.save_all(change_sets: [change_set, change_set_two]) }.to change { query_service.find_all_of_model(model: resource.class).count }.by(2)
    end

    it 'returns an array when saving multiple resources' do
      expect(change_set_persister.save_all(change_sets: [change_set, change_set_two]).class).to eq(Array)
    end
  end

  describe 'deleting' do
    let(:resource) { create_for_repository(:work) }

    it 'can delete a resource' do
      expect { change_set_persister.delete(change_set: Hyrax::WorkChangeSet.new(resource)) }.to change { query_service.find_all_of_model(model: resource.class).count }.by(-1)
    end

    # rubocop:disable Metrics/LineLength
    it 'can delete multiple resources' do
      resource_two = create_for_repository(:work)
      expect { change_set_persister.delete_all(change_sets: [Hyrax::WorkChangeSet.new(resource), Hyrax::WorkChangeSet.new(resource_two)]) }.to change { query_service.find_all_of_model(model: resource.class).count }.by(-2)
    end
    # rubocop:enable Metrics/LineLength
  end
end
