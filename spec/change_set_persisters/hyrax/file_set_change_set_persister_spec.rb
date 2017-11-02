# frozen_string_literals: true

RSpec.describe Hyrax::FileSetChangeSetPersister, type: :model do
  include ActionDispatch::TestProcess

  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }

  let(:change_set_persister) { described_class.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:file) { fixture_file_upload('world.png', 'image/png') }
  let(:change_set) { Hyrax::FileUploadChangeSet.new(file_set, files: [file]) }
  let(:user) { create(:user) }

  before do
    allow(change_set).to receive(:user).and_return(user)
  end

  describe '#save' do
    let(:file_set) { build(:file_set) }

    it 'creates the file set' do
      file_set = change_set_persister.save(change_set: change_set)
      expect(file_set).to be_persisted
      members = Hyrax::Queries.find_members(resource: file_set)
      expect(members.size).to eq(1)
      file_node = members.first
      expect(file_node).to be_kind_of Hyrax::FileNode
      expect(file_node.label).to eq ['world.png']
      expect(file_node.original_filename).to eq ['world.png']
      expect(file_node.mime_type).to eq ['image/png']
      expect(file_node.use).to eq [Valkyrie::Vocab::PCDMUse.OriginalFile]
      file_path = URI(file_node.file_identifiers.first.to_s).path
      expect(File).to exist(file_path)
    end
  end

  describe "#ingest_file" do
    let(:file_set) { create_for_repository(:file_set) }

    context 'when an alternative use is specified' do
      let(:use) { ::RDF::URI('http://pcdm.org/use#IntermediateFile') }

      it 'creates the file set' do
        change_set_persister.send(:ingest_file, resource: file_set, change_set: change_set, use: use)
        members = Hyrax::Queries.find_members(resource: file_set)
        file_node = members.first
        expect(file_node.use).to eq [use]
      end
    end
  end
end
