# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/hydra/works/services/add_file_to_file_set'
require 'wings/services/custom_queries/find_file_metadata'

RSpec.describe Wings::CustomQueries::FindFileMetadata, :active_fedora, :clean_repo do
  subject(:query_handler) { described_class.new(query_service: query_service) }
  let(:query_service) { Hyrax.query_service }
  let(:af_file_id1) { 'file1' }
  let(:valk_id1) { ::Valkyrie::ID.new(af_file_id1) }

  let(:pcdmfile1) do
    Hydra::PCDM::File.new.tap do |f|
      f.id = af_file_id1
      f.content = 'some text for content'
      f.original_name = 'some_text.txt'
      f.mime_type = 'text/plain'
      f.save!
    end
  end

  describe '.queries' do
    it 'lists queries' do
      expect(described_class.queries).to eq [:find_file_metadata_by,
                                             :find_file_metadata_by_alternate_identifier,
                                             :find_many_file_metadata_by_ids,
                                             :find_many_file_metadata_by_use]
    end
  end

  describe '.find_file_metadata_by' do
    context 'when use_valkyrie: false' do
      before { pcdmfile1 }

      it 'returns AF File' do
        result = query_handler.find_file_metadata_by(id: valk_id1, use_valkyrie: false)
        expect(result).to be_a Hydra::PCDM::File
        expect(result.id).to eq af_file_id1
      end
    end

    context 'when use_valkyrie: true' do
      before { pcdmfile1 }

      it 'returns ActiveFedora objects' do
        result = query_handler.find_file_metadata_by(id: valk_id1, use_valkyrie: true)
        expect(result).to be_a Hyrax::FileMetadata
        expect(result.id).to eq valk_id1
      end
    end

    context 'when invalid id' do
      let(:valk_id1) { ::Valkyrie::ID.new('BOGUS') }

      it 'returns error' do
        expect { query_handler.find_file_metadata_by(id: valk_id1) }.to raise_error Hyrax::ObjectNotFoundError
      end
    end

    context 'when it was created with the storage adapter' do
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:storage) { Valkyrie::StorageAdapter.find(:active_fedora) }

      let(:file) do
        Valkyrie::StorageAdapter
          .find(:active_fedora)
          .upload(file: upload, resource: file_set, original_filename: 'name.png')
      end

      let(:upload) do
        f = Tempfile.new('valkyrie-tmp')
        f.write 'some content'
        f.rewind
        f
      end

      it 'returns an existing metadata node' do
        expect(query_handler.find_file_metadata_by(id: file.id)).to be_persisted
      end
    end
  end

  describe '.find_many_file_metadata_by_ids' do
    let(:af_file_id2) { 'file2' }
    let(:valk_id2)    { ::Valkyrie::ID.new(af_file_id2) }
    let(:ids)         { [valk_id1, valk_id2] }

    let(:pcdmfile2) do
      Hydra::PCDM::File.new.tap do |f|
        f.id = af_file_id2
        f.content = 'another text file'
        f.original_name = 'more_text.txt'
        f.mime_type = 'text/plain'
        f.save!
      end
    end

    before do
      pcdmfile1
      pcdmfile2
    end

    context 'when use_valkyrie: false' do
      it 'returns AF Files' do
        result = query_handler.find_many_file_metadata_by_ids(ids: ids, use_valkyrie: false)
        expect(result.first).to be_a Hydra::PCDM::File
        expect(result.map { |fm| fm.id.to_s }).to match_array(ids.map(&:to_s))
      end
    end

    context 'when use_valkyrie: true' do
      it 'returns Hyrax::FileMetadata resources' do
        result = query_handler.find_many_file_metadata_by_ids(ids: ids, use_valkyrie: true)
        expect(result.first).to be_a Hyrax::FileMetadata
        expect(result.map { |fm| fm.id.to_s }).to match_array(ids.map(&:to_s))
      end
    end

    context 'when some ids are for non-file metadata resources' do
      let(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [valk_id1, valk_id2, non_existent_id] }

      it 'only includes file metadata resources' do
        result = query_handler.find_many_file_metadata_by_ids(ids: ids, use_valkyrie: true)
        expect(result.first).to be_a Hyrax::FileMetadata
        expect(result.map { |fm| fm.id.to_s }).to match_array [valk_id1.to_s, valk_id2.to_s]
      end
    end

    context 'when not passed any valid ids' do
      let(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [non_existent_id] }

      it 'result is empty' do
        expect(query_handler.find_many_file_metadata_by_ids(ids: ids)).to be_empty
      end
    end

    context 'when passed empty ids array' do
      let(:ids) { [] }

      it 'result is empty' do
        expect(query_handler.find_many_file_metadata_by_ids(ids: ids)).to be_empty
      end
    end
  end

  describe '.find_file_metadata_by_use' do
    let(:af_file_set) { create(:file_set, id: 'fileset_id') }
    let!(:file_set)   { af_file_set.valkyrie_resource }

    let(:original_file_use)  { Hyrax::FileMetadata::Use::ORIGINAL_FILE }
    let(:extracted_text_use) { Hyrax::FileMetadata::Use::EXTRACTED_TEXT }
    let(:thumbnail_use)      { Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE }

    let(:pdf_filename)  { 'sample-file.pdf' }
    let(:pdf_mimetype)  { 'application/pdf' }
    let(:pdf_file)      { File.open(File.join(fixture_path, pdf_filename)) }

    let(:text_filename) { 'updated-file.txt' }
    let(:text_mimetype) { 'text/plain' }
    let(:text_file)     { File.open(File.join(fixture_path, text_filename)) }

    let(:image_filename) { 'world.png' }
    let(:image_mimetype) { 'image/png' }
    let(:image_file)     { File.open(File.join(fixture_path, image_filename)) }

    context 'when file set has files of the requested use' do
      let!(:file_set) do
        file_set = af_file_set.valkyrie_resource
        file_set = Wings::Works::AddFileToFileSet.call(file_set: file_set, file: pdf_file, type: original_file_use)
        file_set = Wings::Works::AddFileToFileSet.call(file_set: file_set, file: image_file, type: thumbnail_use)
        Wings::Works::AddFileToFileSet.call(file_set: file_set, file: text_file, type: extracted_text_use)
      end

      context 'and use_valkyrie is false' do
        it 'returns AF Files matching use' do
          result = query_handler.find_many_file_metadata_by_use(resource: file_set, use: original_file_use, use_valkyrie: false)
          expect(result.size).to eq 1
          expect(result.first).to be_a Hydra::PCDM::File
          expect(result.first.content).to start_with('%PDF-1.3')
        end
      end

      context 'and use_valkyrie is true' do
        it 'returns Hyrax::FileMetadata resources matching use' do
          result = query_handler.find_many_file_metadata_by_use(resource: file_set, use: extracted_text_use, use_valkyrie: true)
          expect(result.size).to eq 1
          expect(result.first).to be_a Hyrax::FileMetadata
          expect(result.first.pcdm_use).to include extracted_text_use
        end
      end
    end

    context 'when file set has no files of the requested use' do
      let!(:file_set) do
        file_set = af_file_set.valkyrie_resource
        file_set = Wings::Works::AddFileToFileSet.call(file_set: file_set, file: pdf_file, type: original_file_use)
        Wings::Works::AddFileToFileSet.call(file_set: file_set, file: image_file, type: thumbnail_use)
      end

      it 'result is empty' do
        result = query_handler.find_many_file_metadata_by_use(resource: file_set, use: extracted_text_use)
        expect(result).to be_empty
      end
    end

    context 'when file set has no files' do
      it 'result is empty' do
        result = query_handler.find_many_file_metadata_by_use(resource: file_set, use: original_file_use)
        expect(result).to be_empty
      end
    end
  end
end
