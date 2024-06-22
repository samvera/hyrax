# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax do
  describe ".FileMetadata()" do
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

    context 'when trying to cast a resource class' do
      it 'raises an argument error' do
        expect { described_class::FileMetadata(file_set) }
          .to raise_error(ArgumentError)
      end
    end

    context 'when uploaded from a generic storage adapter' do
      let(:storage_adapter) { Valkyrie::StorageAdapter.find(:derivatives_disk) }
      let(:file) do
        storage_adapter.upload(resource: file_set,
                               file: Tempfile.new('moomin'),
                               original_filename: 'test_for_filemetadata')
      end
      let!(:unpersisted_file_meta) { described_class::FileMetadata(file) }
      let(:wings_disabled?) { Hyrax.config.disable_wings }

      it 'builds a new FileMetadata' do
        expect(unpersisted_file_meta).to have_attributes(file_identifier: file.id)
      end

      it 'can recover the metadata after saving' do
        file_meta = Hyrax.persister.save(resource: unpersisted_file_meta)

        expect(described_class::FileMetadata(file)).to eq file_meta unless wings_disabled?
        if wings_disabled?
          expect(unpersisted_file_meta).to have_attributes(
            internal_resource: file_meta.internal_resource,
            original_filename: file_meta.original_filename,
            mime_type: file_meta.mime_type
          )
        end
        expect(unpersisted_file_meta.file_identifier.id).to eq(file_meta.file_identifier.id)
        expect(unpersisted_file_meta.pcdm_use.first.to_s).to eq(file_meta.pcdm_use.first.to_s)
      end
    end
  end
end

RSpec.describe Hyrax::FileMetadata do
  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  subject(:file_metadata) do
    described_class.new(id: 'test_id', format_label: 'test_format_label', label: 'world.png')
  end

  let(:file) { Rack::Test::UploadedFile.new('spec/fixtures/world.png', 'image/png') }
  let(:pcdm_file_uri) { RDF::URI('http://pcdm.org/models#File') }

  it 'sets the proper attributes' do
    expect(file_metadata)
      .to have_attributes(id: 'test_id',
                          format_label: contain_exactly('test_format_label'),
                          label: contain_exactly('world.png'),
                          pcdm_use: contain_exactly(described_class::Use::ORIGINAL_FILE))
  end

  context 'when saved with a file' do
    let(:file) { create(:uploaded_file, file: File.open('spec/fixtures/world.png')) }
    let(:file_metadata) { valkyrie_create(:file_metadata, :original_file, :with_file, file: file) }
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [file_metadata], original_file: file_metadata) }

    it 'can be changed and saved' do
      file_metadata.creator = 'Tove'

      expect(Hyrax.persister.save(resource: file_metadata).creator)
        .to contain_exactly('Tove')
    end

    it 'contains file metadata' do
      expect(file_metadata)
        .to have_attributes(mime_type: 'image/png',
                            original_filename: 'world.png')
    end
  end

  describe '#original_file?' do
    context 'when use says file is the original file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.to be_original_file }
    end

    context 'when use does not say file is the original file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::THUMBNAIL_IMAGE, pcdm_file_uri]
      end

      it { is_expected.not_to be_original_file }
    end
  end

  describe '#thumbnail_file?' do
    context 'when use says file is the thumbnail file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::THUMBNAIL_IMAGE, pcdm_file_uri]
      end

      it { is_expected.to be_thumbnail_file }
    end

    context 'when use does not say file is the thumbnail file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.not_to be_thumbnail_file }
    end
  end

  describe '#extracted_file?' do
    context 'when use says file is the extracted file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::EXTRACTED_TEXT, pcdm_file_uri]
      end

      it { is_expected.to be_extracted_file }
    end

    context 'when use does not say file is the extracted file' do
      before do
        file_metadata.pcdm_use = [described_class::Use::ORIGINAL_FILE, pcdm_file_uri]
      end

      it { is_expected.not_to be_extracted_file }
    end
  end

  describe '#filtered_pcdm_use' do
    context 'when use contains extraneous entries' do
      before do
        file_metadata.pcdm_use = [RDF::Vocab::Fcrepo4.Binary,
                                  described_class::Use::ORIGINAL_FILE,
                                  described_class::Use::EXTRACTED_TEXT,
                                  pcdm_file_uri]
      end

      it 'returns only recognized uses' do
        expect(file_metadata.filtered_pcdm_use).to eq [described_class::Use::ORIGINAL_FILE,
                                                       described_class::Use::EXTRACTED_TEXT]
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
    it 'raises an error for a missing file_identifier' do
      expect { file_metadata.file }
        .to raise_error Valkyrie::StorageAdapter::AdapterNotFoundError
    end

    context 'when file_identifier is saved with storage_adapter' do
      let(:file_metadata) { described_class.new(file_identifier: stored.id) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

      let(:stored) do
        Hyrax.storage_adapter.upload(resource: file_set,
                                     file: file,
                                     original_filename: file.original_filename)
      end

      it 'gives the exact file' do
        expect(file_metadata.file.read).to eq stored.read
      end
    end

    context 'when file_identifier is saved with an arbitrary adapter' do
      let(:file_metadata) { described_class.new(file_identifier: stored.id) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

      let(:stored) do
        Valkyrie::StorageAdapter
          .find(:test_disk)
          .upload(resource: file_set,
                  file: file,
                  original_filename: file.original_filename)
      end

      it 'gives the exact file' do
        expect(file_metadata.file.read).to eq stored.read
      end
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
