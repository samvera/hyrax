# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::FileMetadata do
  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }
  let(:subject) do
    described_class.for(file: file).new(id: 'test_id', format_label: 'test_format_label')
  end
  let(:pcdm_file_uri) { RDF::URI('http://pcdm.org/models#File') }

  it 'sets the proper attributes' do
    expect(subject.id.to_s).to eq 'test_id'
    expect(subject.label).to contain_exactly('world.png')
    expect(subject.original_filename).to contain_exactly('world.png')
    expect(subject.mime_type).to contain_exactly('image/png')
    expect(subject.format_label).to contain_exactly('test_format_label')
    expect(subject.use).to contain_exactly(Hyrax::FileSet.original_file_use)
  end

  describe '#original_file?' do
    context 'when use says file is the original file' do
      before { subject.use = [Hyrax::FileSet.original_file_use, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_original_file
      end
    end
    context 'when use does not say file is the original file' do
      before { subject.use = [Hyrax::FileSet.thumbnail_use, pcdm_file_uri] }
      it 'returns false' do
        expect(subject).not_to be_original_file
      end
    end
  end

  describe '#thumbnail_file?' do
    context 'when use says file is the thumbnail file' do
      before { subject.use = [Hyrax::FileSet.thumbnail_use, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_thumbnail_file
      end
    end
    context 'when use does not say file is the thumbnail file' do
      before { subject.use = [Hyrax::FileSet.original_file_use, pcdm_file_uri] }
      it 'returns false' do
        expect(subject).not_to be_thumbnail_file
      end
    end
  end

  describe '#extracted_file?' do
    context 'when use says file is the extracted file' do
      before { subject.use = [Hyrax::FileSet.extracted_text_use, pcdm_file_uri] }
      it 'returns true' do
        expect(subject).to be_extracted_file
      end
    end
    context 'when use does not say file is the extracted file' do
      before { subject.use = [Hyrax::FileSet.original_file_use, pcdm_file_uri] }
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

  describe "#valid?" do
    it do
      pending 'TODO: configure and test checksums'
      is_expected.to be_valid
    end
  end

  describe '#file' do
    it 'returns file from storage adapter' do
      expect(subject.file).to be_a Valkyrie::StorageAdapter::StreamFile
    end
  end

  describe '#versions' do
    context 'when no versions saved' do
      it 'returns empty array' do
        pending 'TODO: write test when Wings file versioning is implemented (Issue #3923)'
        expect(subject.versions).to eq []
      end
    end
    context 'when versions saved' do
      it 'returns a set of file_metadatas for previous versions' do
        pending 'TODO: write test when Wings file versioning is implemented (Issue #3923)'
        expect(false).to be true
      end
    end
  end
end
