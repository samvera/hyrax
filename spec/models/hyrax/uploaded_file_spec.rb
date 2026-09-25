# frozen_string_literal: true
RSpec.describe Hyrax::UploadedFile do
  let(:file1) { File.open(fixture_path + '/world.png') }
  let(:user) { create(:user) }

  subject { described_class.create(file: file1) }

  it "is not in the public directory" do
    temp_dir = Rails.root + 'tmp'
    expect(subject.file.path).to start_with temp_dir.to_s
  end

  it "scans for viruses" do
    allow(Hyrax::VirusScanner).to receive(:infected?).and_return(true)
    expect(subject.errors[:file]).to include(/Virus detected/)
  end

  shared_examples 'a storage-neutral staged upload' do
    describe '#filename' do
      it 'returns the name of the stored file' do
        expect(upload.filename).to eq 'world.png'
      end

      it 'is nil when no file is stored' do
        expect(described_class.new.filename).to be_nil
      end
    end

    describe '#content_type' do
      it 'returns the MIME type of the stored file' do
        expect(upload.content_type).to eq 'image/png'
      end
    end

    describe '#byte_size' do
      it 'returns the size of the stored file' do
        expect(upload.byte_size).to eq File.size(fixture_path + '/world.png')
      end
    end

    describe '#stored?' do
      it 'is true when a file is stored' do
        expect(upload).to be_stored
      end

      it 'is false when no file is stored' do
        expect(described_class.new).not_to be_stored
      end
    end

    describe '#with_io' do
      it 'yields a readable IO positioned at the start of the content' do
        content = upload.with_io(&:read)

        expect(content).to eq File.binread(fixture_path + '/world.png')
      end

      it 'yields an IO with a local filesystem path' do
        upload.with_io do |io|
          expect(File).to exist(io.path)
        end
      end

      it 'closes the IO after the block returns' do
        leaked = upload.with_io { |io| io }

        expect(leaked).to be_closed
      end

      it 'returns the value of the block' do
        expect(upload.with_io { :result }).to eq :result
      end

      it 'raises ArgumentError without a block' do
        expect { upload.with_io }.to raise_error ArgumentError
      end
    end

    describe '#with_local_path' do
      it 'yields a path to the stored content' do
        upload.with_local_path do |path|
          expect(File.binread(path)).to eq File.binread(fixture_path + '/world.png')
        end
      end

      it 'returns the value of the block' do
        expect(upload.with_local_path { :result }).to eq :result
      end

      it 'raises ArgumentError without a block' do
        expect { upload.with_local_path }.to raise_error ArgumentError
      end
    end
  end

  describe 'with the :carrierwave storage backend' do
    let(:upload) { described_class.create(file: file1, user: user) }

    it_behaves_like 'a storage-neutral staged upload'

    it 'does not use Active Storage' do
      expect(upload).not_to be_active_storage_backed
    end
  end

  describe 'with the :active_storage storage backend' do
    around do |example|
      original = Hyrax.config.uploaded_file_storage_backend
      Hyrax.config.uploaded_file_storage_backend = :active_storage
      example.run
      Hyrax.config.uploaded_file_storage_backend = original
    end

    let(:upload) { described_class.create(file: file1, user: user) }

    it_behaves_like 'a storage-neutral staged upload'

    it 'stores content through Active Storage' do
      expect(upload).to be_active_storage_backed
      expect(upload.file_attachment).to be_attached
    end

    it 'leaves the CarrierWave uploader empty' do
      expect(upload.uploader.file).to be_nil
    end

    it 'records an intended filename ahead of content' do
      pending_upload = described_class.create(file: 'incoming.png', user: user)

      expect(pending_upload.filename).to eq 'incoming.png'
      expect(pending_upload).not_to be_stored
      expect(pending_upload.byte_size).to be_nil
    end

    describe '#store_file' do
      it 'attaches an IO under the given filename' do
        upload = described_class.create(file: 'incoming.png', user: user)
        File.open(fixture_path + '/world.png', 'rb') do |io|
          upload.store_file(io, filename: upload.filename)
        end

        expect(upload.reload.filename).to eq 'incoming.png'
        expect(upload.byte_size).to eq File.size(fixture_path + '/world.png')
        expect(upload.with_io(&:read)).to eq File.binread(fixture_path + '/world.png')
      end

      it 'accepts an upload object carrying its own filename' do
        upload = described_class.create(user: user)
        upload.store_file(Rack::Test::UploadedFile.new(File.join(fixture_path, 'world.png'), 'image/png'))

        expect(upload.reload.filename).to eq 'world.png'
      end
    end

    it 'scans new content for viruses' do
      allow(Hyrax::VirusScanner).to receive(:infected?).and_return(true)
      upload = described_class.create(file: file1, user: user)

      expect(upload.errors[:file]).to include(/Virus detected/)
      expect(upload).not_to be_persisted
    end

    it 'does not rescan unchanged content on later saves' do
      upload = described_class.create(file: file1, user: user)

      expect(Hyrax::VirusScanner).not_to receive(:infected?)
      upload.update!(file_set_uri: 'test:fs')
    end

    it 'purges the attachment when destroyed' do
      upload # create before the expectation

      expect { upload.destroy }.to have_enqueued_job(ActiveStorage::PurgeJob)
    end
  end
end
