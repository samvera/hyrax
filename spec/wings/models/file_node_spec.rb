# frozen_string_literal: true
require 'wings/models/file_node'
require 'wings/models/multi_checksum'

RSpec.describe Wings::FileNode do
  let(:adapter) { Wings::Valkyrie::MetadataAdapter.new }
  let(:persister) { adapter.persister }
  let(:storage_adapter) { Valkyrie::Storage::Memory.new }
  let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }
  let(:subject) do
    described_class.for(file: file).new(id: 'test_id', format_label: 'test_format_label')
  end
  let(:uploaded_file) do
    storage_adapter.upload(file: file,
                           original_filename: file.original_filename,
                           resource: subject)
  end
  let(:pcdm_file_uri) { RDF::URI('http://pcdm.org/models#File') }

  before do
    stub_request(:get, 'http://test_id/original').to_return(status: 200, body: "", headers: {})

    subject.file_identifiers = uploaded_file.id
    subject.checksum = Wings::MultiChecksum.for(uploaded_file)
    subject.size = uploaded_file.size
    persister.save(resource: subject)
  end

  it 'sets the proper attributes' do
    expect(subject.id.to_s).to eq 'test_id'
    expect(subject.label).to contain_exactly('world.png')
    expect(subject.original_filename).to contain_exactly('world.png')
    expect(subject.mime_type).to contain_exactly('image/png')
    expect(subject.format_label).to contain_exactly('test_format_label')
    expect(subject.use).to contain_exactly(Valkyrie::Vocab::PCDMUse.OriginalFile)
  end

  describe '#original_file?' do
    context 'when use says file is the original file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.OriginalFile, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_original_file
      end
    end
    context 'when use does not say file is the original file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.ThumbnailImage, pcdm_file_uri] }
      it 'returns false' do
        expect(subject).not_to be_original_file
      end
    end
  end

  describe '#thumbnail_file?' do
    context 'when use says file is the thumbnail file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.ThumbnailImage, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_thumbnail_file
      end
    end
    context 'when use does not say file is the thumbnail file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.OriginalFile, pcdm_file_uri] }
      it 'returns false' do
        expect(subject).not_to be_thumbnail_file
      end
    end
  end

  describe '#extracted_file?' do
    context 'when use says file is the extracted file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.ExtractedImage, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_extracted_file
      end
    end
    context 'when use does not say file is the extracted file' do
      before { subject.use = [Valkyrie::Vocab::PCDMUse.OriginalFile, pcdm_file_uri] }
      it 'returns false' do
        expect(subject).not_to be_extracted_file
      end
    end
  end

  describe '#title' do
    it 'uses the label' do
      expect(subject.title).to contain_exactly('world.png')
    end
  end

  describe '#download_id' do
    it 'uses the id' do
      expect(subject.download_id.to_s).to eq 'test_id'
    end
  end

  describe '#file_node?' do
    it 'is a file_node' do
      expect(subject).to be_file_node
    end
  end

  describe '#file_set?' do
    it 'is not a file_set' do
      expect(subject).not_to be_file_set
    end
  end

  describe '#work?' do
    it 'is not a work' do
      expect(subject).not_to be_work
    end
  end

  describe '#collection?' do
    it 'is not a collection' do
      expect(subject).not_to be_collection
    end
  end

  describe "#valid?" do
    it 'is valid' do
      pending 'TODO: Fix issue when using in-memory storage adapter.'
      expect(subject).to be_valid
    end
  end

  describe '#file' do
    it 'returns file from storage adapter' do
      pending 'TODO: Fix issue when using in-memory storage adapter.'
      expect(subject.file).to be_a Valkyrie::StorageAdapter::StreamFile
    end
  end

  describe '#versions' do
    context 'when no versions saved' do
      it 'returns empty array' do
        expect(subject.versions).to eq []
      end
    end
    context 'when versions saved' do
      it 'returns a set of file_nodes for previous versions' do
        pending 'TODO: write test when Wings file versioning is implemented'
        expect(false).to be true
      end
    end
  end
end
