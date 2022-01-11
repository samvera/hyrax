# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::FileMetadata do
  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  subject(:file_metadata) do
    described_class.for(file: file).new(id: 'test_id', format_label: 'test_format_label')
  end

  let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }
  let(:pcdm_file_uri) { RDF::URI('http://pcdm.org/models#File') }

  it 'sets the proper attributes' do
    expect(file_metadata)
      .to have_attributes(id: 'test_id',
                          format_label: contain_exactly('test_format_label'),
                          label: contain_exactly('world.png'),
                          mime_type: 'image/png',
                          original_filename: 'world.png',
                          type: contain_exactly(described_class::Use::ORIGINAL_FILE))
  end

  context 'when saved with a file' do
    subject(:file_metadata) { Hyrax.custom_queries.find_file_metadata_by(id: file.id) }
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

    let(:file) do
      Hyrax.storage_adapter.upload(resource: file_set,
                                   file: Tempfile.new('blah'),
                                   original_filename: 'blah.txt')
    end

    it 'can be changed and saved' do
      file_metadata.creator = 'Tove'

      expect(Hyrax.persister.save(resource: file_metadata).creator)
        .to contain_exactly('Tove')
    end
  end

  describe '#original_file?' do
    context 'when use says file is the original file' do
      before do
        file_metadata.type = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.to be_original_file }
    end

    context 'when use does not say file is the original file' do
      before do
        file_metadata.type = [described_class::Use::THUMBNAIL, pcdm_file_uri]
      end

      it { is_expected.not_to be_original_file }
    end
  end

  describe '#thumbnail_file?' do
    context 'when use says file is the thumbnail file' do
      before do
        file_metadata.type = [described_class::Use::THUMBNAIL, pcdm_file_uri]
      end

      it { is_expected.to be_thumbnail_file }
    end

    context 'when use does not say file is the thumbnail file' do
      before do
        file_metadata.type = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.not_to be_thumbnail_file }
    end
  end

  describe '#extracted_file?' do
    context 'when use says file is the extracted file' do
      before do
        file_metadata.type = [described_class::Use::EXTRACTED_TEXT, pcdm_file_uri]
      end

      it { is_expected.to be_extracted_file }
    end

    context 'when use does not say file is the extracted file' do
      before do
        file_metadata.type = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.not_to be_extracted_file }
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
