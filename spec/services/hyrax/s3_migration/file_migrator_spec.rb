# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::FileMigrator do
  let(:file_metadata) { Struct.new(:id, :file_identifier, :checksum, :original_filename, keyword_init: true) }
  let(:dir) { Dir.mktmpdir }
  let(:content) { 'original file bytes' }
  let(:disk_file) { File.join(dir, 'a.txt') }
  let(:file_set) { instance_double(Hyrax::FileSet, id: Valkyrie::ID.new('fs1')) }
  let(:checksum) { [] }
  let(:identifier) { "disk://#{disk_file}" }
  let(:original) do
    file_metadata.new(id: Valkyrie::ID.new('fm1'), file_identifier: Valkyrie::ID.new(identifier),
                      checksum:, original_filename: ['a.txt'])
  end
  let(:current) { file_metadata.new(id: original.id, file_identifier: original.file_identifier) }
  let(:uploaded) { Struct.new(:id).new(Valkyrie::ID.new('shrine://fs1/uuid')) }
  let(:s3_content) { content }
  let(:s3_storage) { double('s3_storage', upload: uploaded, delete: nil) }
  let(:manifest) { instance_double(Hyrax::S3Migration::Manifest, write: nil) }
  let(:dry_run) { false }

  subject(:result) do
    described_class.new(file_set:, original:, dry_run:, s3_storage:, manifest:).call
  end

  before do
    File.write(disk_file, content)
    s3_file = Valkyrie::StorageAdapter::File.new(id: uploaded.id, io: StringIO.new(s3_content))
    allow(s3_storage).to receive(:find_by).with(id: uploaded.id).and_return(s3_file)
    allow(Hyrax.query_service).to receive(:find_by).with(id: original.id).and_return(current)
    allow(Hyrax.persister).to receive(:save)
    allow(Hyrax.index_adapter).to receive(:save)
  end

  after { FileUtils.remove_entry(dir) }

  context 'with a verified copy' do
    it 'migrates, records the manifest entry and switches the identifier' do
      expect(result.status).to eq :migrated
      expect(current.file_identifier).to eq uploaded.id
      expect(Hyrax.persister).to have_received(:save).with(resource: current)
      expect(Hyrax.index_adapter).not_to have_received(:save)
      expect(manifest).to have_received(:write).with(hash_including(
                                                       file_set_id: 'fs1', file_metadata_id: 'fm1',
                                                       old_id: identifier, new_id: 'shrine://fs1/uuid',
                                                       size: content.bytesize, sha256: Digest::SHA256.hexdigest(content)
                                                     ))
    end

    it 'keeps the disk copy and the upload' do
      result
      expect(File.read(disk_file)).to eq content
      expect(s3_storage).not_to have_received(:delete)
    end
  end

  describe 'reading the disk file' do
    before { allow(File).to receive(:open).and_call_original }

    it 'opens it once to hash and once to upload' do
      expect(result.status).to eq :migrated
      expect(File).to have_received(:open).with(disk_file, 'rb').twice
    end

    context 'with a stored checksum' do
      let(:checksum) { [Digest::MD5.hexdigest(content)] }

      it 'still hashes in a single pass' do
        expect(result.status).to eq :migrated
        expect(File).to have_received(:open).with(disk_file, 'rb').twice
      end
    end

    context 'when this is a dry run with a stored checksum' do
      let(:dry_run) { true }
      let(:checksum) { [Digest::MD5.hexdigest(content)] }

      it 'opens it once' do
        expect(result.status).to eq :would_migrate
        expect(File).to have_received(:open).with(disk_file, 'rb').once
      end
    end

    context 'when this is a dry run with nothing to compare against' do
      let(:dry_run) { true }

      it 'does not open it at all' do
        expect(result.status).to eq :would_migrate
        expect(File).not_to have_received(:open).with(disk_file, 'rb')
      end
    end

    context 'when it hashes a file larger than one chunk' do
      let(:content) { 'x' * (described_class::CHUNK_SIZE + 10) }
      let(:checksum) { [Digest::MD5.hexdigest(content)] }

      it 'matches the digests of the whole file' do
        expect(result.status).to eq :migrated
        expect(manifest).to have_received(:write).with(hash_including(sha256: Digest::SHA256.hexdigest(content)))
      end
    end
  end

  context 'when this is a dry run' do
    let(:dry_run) { true }

    it 'reports what it would do and changes nothing' do
      expect(result.status).to eq :would_migrate
      expect(s3_storage).not_to have_received(:upload)
      expect(Hyrax.persister).not_to have_received(:save)
    end
  end

  context 'when the file is already in S3' do
    let(:identifier) { 'shrine://fs1/existing' }

    it { expect(result.status).to eq :already_migrated }
  end

  context 'when the storage is not disk or S3' do
    let(:identifier) { 'fedora://thing' }

    it { expect(result.status).to eq :unrecognised }
  end

  context 'when the disk file is missing' do
    before { FileUtils.rm(disk_file) }

    it 'reports it and does not upload' do
      expect(result.status).to eq :missing
      expect(s3_storage).not_to have_received(:upload)
    end
  end

  context 'with a stored checksum' do
    context 'when an MD5 matches' do
      let(:checksum) { [Digest::MD5.hexdigest(content)] }

      it { expect(result.status).to eq :migrated }
    end

    context 'when a urn:sha1: checksum matches' do
      let(:checksum) { ["urn:sha1:#{Digest::SHA1.hexdigest(content)}"] }

      it { expect(result.status).to eq :migrated }
    end

    context 'when the disk file does not match' do
      let(:checksum) { [Digest::MD5.hexdigest('something else')] }

      it 'flags the file as suspect without uploading' do
        expect(result.status).to eq :suspect
        expect(s3_storage).not_to have_received(:upload)
      end
    end

    context 'when the checksum is in a format we do not recognise' do
      let(:checksum) { ['not-a-hex-digest'] }

      it { expect(result.status).to eq :migrated }
    end

    context 'when a bare hex value has no known length' do
      let(:checksum) { [Digest::SHA1.hexdigest('something else')] }

      it 'does not treat it as a mismatch' do
        expect(result.status).to eq :migrated
      end
    end

    context 'when a urn:sha1: checksum does not match' do
      let(:checksum) { ["urn:sha1:#{Digest::SHA1.hexdigest('something else')}"] }

      it { expect(result.status).to eq :suspect }
    end
  end

  context 'when the S3 copy does not match the disk file' do
    let(:s3_content) { 'corrupted bytes!!!!!!' }

    it 'removes the upload and leaves the identifier alone' do
      expect(result.status).to eq :mismatch
      expect(s3_storage).to have_received(:delete).with(id: uploaded.id)
      expect(Hyrax.persister).not_to have_received(:save)
      expect(manifest).not_to have_received(:write)
    end
  end

  context 'when another process migrated the file first' do
    before { current.file_identifier = Valkyrie::ID.new('shrine://fs1/other') }

    it 'removes its own upload and does not save' do
      expect(result.status).to eq :raced
      expect(s3_storage).to have_received(:delete).with(id: uploaded.id)
      expect(Hyrax.persister).not_to have_received(:save)
    end
  end

  context 'when saving fails' do
    before { allow(Hyrax.persister).to receive(:save).and_raise(StandardError, 'db down') }

    it 'raises and removes the unreferenced upload' do
      expect { result }.to raise_error(StandardError, 'db down')
      expect(s3_storage).to have_received(:delete).with(id: uploaded.id)
    end
  end

  context 'when writing the manifest fails' do
    before { allow(manifest).to receive(:write).and_raise(StandardError, 's3 down') }

    it 'raises, removes the upload and leaves the identifier on disk' do
      expect { result }.to raise_error(StandardError, 's3 down')
      expect(s3_storage).to have_received(:delete).with(id: uploaded.id)
      expect(Hyrax.persister).not_to have_received(:save)
    end
  end
end
