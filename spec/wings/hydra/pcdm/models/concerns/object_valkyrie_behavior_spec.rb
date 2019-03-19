# frozen_string_literal: true
require 'wings_helper'
require 'wings/model_transformer'

RSpec.describe Wings::Pcdm::ObjectValkyrieBehavior, :clean_repo do
  subject(:factory) { Wings::ModelTransformer.new(pcdm_object: pcdm_object) }

  let(:resource) { subject.build }

  let(:work1)       { build(:work, id: 'wk1', title: ['Work 1']) }
  let(:fileset1)    { build(:file_set, id: 'fs1', title: ['Fileset 1']) }

  describe 'type check methods on valkyrie resource' do
    let(:pcdm_object) { work1 }

    it 'returns appropriate response from type check methods' do
      expect(resource.pcdm_collection?).to be false
      expect(resource.pcdm_object?).to be true
    end
  end

  describe 'filter file types' do
    let(:pcdm_object) { fileset1 }

    let(:thumbnail) do
      file = fileset1.files.build
      Hydra::PCDM::AddTypeToFile.call(file, pcdm_thumbnail_uri)
    end

    let(:file) { add_metadata_to_file(fileset1.files.build) }
    let(:pcdm_thumbnail_uri) { ::RDF::URI('http://pcdm.org/ThumbnailImage') }

    before do
      fileset1.save
      file
    end

    describe 'filter_files_by_type' do
      context 'when the object has files with that type' do
        before { thumbnail }

        it 'allows you to filter the contained files by type URI' do
          expect(resource.filter_files_by_type(pcdm_thumbnail_uri)).to eq [thumbnail]
        end
        it 'only overrides the #files method when you specify :type' do
          expect(resource.files).to match_array [file, thumbnail]
        end
      end

      context 'when the object does NOT have any files with that type' do
        it 'returns an empty array' do
          expect(resource.filter_files_by_type(pcdm_thumbnail_uri)).to eq []
        end
      end
    end

    describe 'file_of_type' do
      context 'when the object has files with that type' do
        before { thumbnail }

        it 'returns the first file with the requested type' do
          expect(resource.file_of_type(pcdm_thumbnail_uri)).to eq thumbnail
        end
      end

      context 'when the object does NOT have any files with that type' do
        it 'initializes a contained file with the requested type' do
          returned_file = resource.file_of_type(pcdm_thumbnail_uri)
          expect(returned_file).to be_new_record
          expect(returned_file.metadata_node.get_values(:type)).to include(pcdm_thumbnail_uri)
          expect(resource.files).to include(returned_file)
        end
      end
    end
  end

  private

    def add_metadata_to_file(file)
      # These are accessible from the FileSet through...
      #   fileset1.files.first.metadata_node.attributes
      file.file_name = 'picture.jpg'
      file.content = 'hello world'
      file.date_created = Date.parse 'Fri, 08 May 2015 08:00:00 -0400 (EDT)'
      file.date_modified = Date.parse 'Sat, 09 May 2015 09:00:00 -0400 (EDT)'
      file.byte_order = 'little-endian'
      file.mime_type = 'application/jpg'
      file
    end
end
