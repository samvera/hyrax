# frozen_string_literals: true

RSpec.describe Hyrax::RevertFileChangeSetPersister do
  describe '#revert_content' do
    let(:file_set) { create_for_repository(:file_set, user: user, content: fixture_file_upload(file1)) }
    let(:file1)    { "small_file.txt" }
    let(:version1) { "version1" }
    let(:restored_content) { file_set.reload.original_file }
    let(:user) { create(:user) }
    let(:actor) { Hyrax::Actors::FileActor.new(file_set, Valkyrie::Vocab::PCDMUse.OriginalFile, user) }

    let(:reloaded) { Hyrax::Queries.find_by(id: file_set.id) }
    let(:huf) { Hyrax::UploadedFile.new(user: user, file: fixture_file_upload('hyrax_generic_stub.txt')) }
    let(:io) { JobIoWrapper.new(file_set_id: file_set.id, user: user, uploaded_file: huf, path: huf.uploader.path) }

    let(:persister) do
      described_class.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
                          storage_adapter: Valkyrie.config.storage_adapter)
    end
    let(:change_set) { Hyrax::RevertFileChangeSet.new(file_set, revision: 'version1') }

    before do
      # Create a second version of the file
      actor.ingest_file(io)
    end

    it "restores the first versions's content and metadata" do
      persister.save(change_set: change_set)
      expect(reloaded.original_file.original_filename).to eq [file1]
    end
  end
end
