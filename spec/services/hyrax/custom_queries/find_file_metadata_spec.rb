RSpec.describe Hyrax::CustomQueries::FindFileMetadata do
  before do
    query_service.custom_queries.register_query_handler(described_class)
  end
  let(:metadata_adapter) { Valkyrie::Persistence::Memory::MetadataAdapter.new }
  let(:query_service) { metadata_adapter.query_service }
  let(:persister) { metadata_adapter.persister }

  let(:id1) { 'file1' }
  let(:alt_id1) { 'file1_alt' }
  let(:valk_id1) { ::Valkyrie::ID.new(id1) }
  let(:valk_alt_id1) { ::Valkyrie::ID.new(alt_id1) }
  let(:content1) { 'some text for content' }
  let(:original_filename1) { 'some_text.txt' }
  let(:mimetype1) { 'text/plain' }
  let(:file_metadata) do
    Hyrax::FileMetadata.new.tap do |fm|
      fm.id = valk_id1
      fm.alternate_ids = valk_alt_id1
      fm.content = content1
      fm.original_filename = original_filename1
      fm.mime_type = mimetype1
      persister.save(resource: fm)
    end
  end

  let(:id2) { 'file2' }
  let(:alt_id2) { 'file2_alt' }
  let(:valk_id2) { ::Valkyrie::ID.new(id2) }
  let(:valk_alt_id2) { ::Valkyrie::ID.new(alt_id2) }
  let(:content2) { '<h3>other context we should not find</h3>' }
  let(:original_filename2) { 'other_text.html' }
  let(:mimetype2) { 'text/html' }
  let(:file_metadata2) do
    Hyrax::FileMetadata.new.tap do |fm|
      fm.id = valk_id2
      fm.alternate_ids = valk_alt_id2
      fm.content = content2
      fm.original_filename = original_filename2
      fm.mime_type = mimetype2
      persister.save(resource: fm)
    end
  end

  describe '.find_file_metadata_by' do
    subject { query_service.custom_queries.find_file_metadata_by(id: valk_id) }
    context 'when file exists' do
      before do
        file_metadata
        file_metadata2
      end
      let(:valk_id) { valk_id1 }
      it 'returns file metadata resource' do
        expect(subject.is_a?(Hyrax::FileMetadata)).to be true
        expect(subject.id.to_s).to eq id1
        expect(subject.alternate_ids.first.to_s).to eq alt_id1
        expect(subject.content.first).to eq content1
        expect(subject.original_filename.first).to eq original_filename1
        expect(subject.mime_type.first).to eq mimetype1
      end
    end

    context 'when file does not exist' do
      before do
        file_metadata
        file_metadata2
      end
      let(:valk_id) { ::Valkyrie::ID.new('BOGUS') }
      it 'raises not found error' do
        expect { subject }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end

  describe '.find_file_metadata_by_alternate_identifier' do
    subject { query_service.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: valk_alt_id) }
    context 'when file exists' do
      before do
        file_metadata
        file_metadata2
      end
      let(:valk_alt_id) { valk_alt_id2 }
      it 'returns file metadata resource' do
        expect(subject.is_a?(Hyrax::FileMetadata)).to be true
        expect(subject.id.to_s).to eq id2
        expect(subject.alternate_ids.first.to_s).to eq alt_id2
        expect(subject.content.first).to eq content2
        expect(subject.original_filename.first).to eq original_filename2
        expect(subject.mime_type.first).to eq mimetype2
      end
    end

    context 'when file does not exist' do
      before do
        file_metadata
        file_metadata2
      end
      let(:valk_alt_id) { ::Valkyrie::ID.new('BOGUS') }
      it 'raises not found error' do
        expect { subject }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
