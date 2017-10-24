RSpec.describe Hyrax::WorkChangeSetPersister, type: :model do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

  describe 'deleteing a work and its file_sets' do
    let(:delete_work) { create_for_repository(:work_with_file_and_work) }

    it 'deletes members that are file_sets' do
      change_set_persister.save(change_set: Hyrax::WorkChangeSet.new(delete_work))
      expect { change_set_persister.cleanup_file_sets(change_set: Hyrax::WorkChangeSet.new(delete_work)) }.to change { query_service.find_all_of_model(model: ::FileSet).count }.by(-1)
    end

    it 'removes the file_set from the resource member ids' do
      change_set_persister.cleanup_file_sets(change_set: Hyrax::WorkChangeSet.new(delete_work))
      expect(query_service.find_by(id: delete_work.id).member_ids.size).to eq(1)
    end

    it 'does not delete non file_set members from the resource' do
      change_set_persister.save(change_set: Hyrax::WorkChangeSet.new(delete_work))
      expect { change_set_persister.cleanup_file_sets(change_set: Hyrax::WorkChangeSet.new(delete_work)) }.not_to change { query_service.find_all_of_model(model: GenericWork).count }
    end

    it 'deletes the file_set when deleting the work' do
      change_set_persister.save(change_set: Hyrax::WorkChangeSet.new(delete_work))
      expect { change_set_persister.delete(change_set: Hyrax::WorkChangeSet.new(delete_work)) }.to change { query_service.find_all_of_model(model: ::FileSet).count }.by(-1)
    end
  end
end
