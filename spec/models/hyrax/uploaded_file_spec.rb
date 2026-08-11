# frozen_string_literal: true
RSpec.describe Hyrax::UploadedFile do
  let(:file1) { File.open(fixture_path + '/world.png') }

  subject { described_class.create(file: file1) }

  it "is not in the public directory" do
    temp_dir = Rails.root + 'tmp'
    expect(subject.file.path).to start_with temp_dir.to_s
  end

  it "scans for viruses" do
    allow(Hyrax::VirusScanner).to receive(:infected?).and_return(true)
    expect(subject.errors[:file]).to include(/Virus detected/)
  end

  describe 'the storage-neutral file API' do
    describe '#filename' do
      it 'returns the name of the stored file' do
        expect(subject.filename).to eq 'world.png'
      end

      it 'is nil when no file is stored' do
        expect(described_class.new.filename).to be_nil
      end
    end

    describe '#content_type' do
      it 'returns the MIME type of the stored file' do
        expect(subject.content_type).to eq 'image/png'
      end
    end

    describe '#byte_size' do
      it 'returns the size of the stored file' do
        expect(subject.byte_size).to eq File.size(fixture_path + '/world.png')
      end
    end

    describe '#stored?' do
      it 'is true when a file is stored' do
        expect(subject).to be_stored
      end

      it 'is false when no file is stored' do
        expect(described_class.new).not_to be_stored
      end
    end

    describe '#with_io' do
      it 'yields a readable IO positioned at the start of the content' do
        content = subject.with_io(&:read)

        expect(content).to eq File.binread(fixture_path + '/world.png')
      end

      it 'yields an IO with a local filesystem path' do
        subject.with_io do |io|
          expect(File).to exist(io.path)
        end
      end

      it 'closes the IO after the block returns' do
        leaked = subject.with_io { |io| io }

        expect(leaked).to be_closed
      end

      it 'returns the value of the block' do
        expect(subject.with_io { :result }).to eq :result
      end

      it 'raises ArgumentError without a block' do
        expect { subject.with_io }.to raise_error ArgumentError
      end
    end

    describe '#with_local_path' do
      it 'yields a path to the stored content' do
        subject.with_local_path do |path|
          expect(File.binread(path)).to eq File.binread(fixture_path + '/world.png')
        end
      end

      it 'returns the value of the block' do
        expect(subject.with_local_path { :result }).to eq :result
      end

      it 'raises ArgumentError without a block' do
        expect { subject.with_local_path }.to raise_error ArgumentError
      end
    end
  end
end
