# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Wings::Valkyrie::Storage, :active_fedora, :clean_repo do
  subject(:storage_adapter) { described_class.new }
  let(:file) { fixture_file_upload('/world.png', 'image/png') }

  it_behaves_like "a Valkyrie::StorageAdapter"

  context 'when accessing an existing AF file' do
    let(:content)  { StringIO.new("test content") }
    let(:file_set) { FactoryBot.create(:file_set) }

    before do
      Hydra::Works::AddFileToFileSet
        .call(file_set, content, :original_file, versioning: true)
    end

    describe '#find_versions' do
      let(:new_content) { StringIO.new("new content") }

      it 'lists versioned ids' do
        id = Hyrax::Base.id_to_uri(file_set.original_file.id)

        expect { Hydra::Works::AddFileToFileSet.call(file_set, new_content, :original_file, versioning: true) }
          .to change { storage_adapter.find_versions(id: id).size }
          .from(1)
          .to(2)
      end

      it 'can retrieve versioned content' do
        id = Hyrax::Base.id_to_uri(file_set.original_file.id)

        Hydra::Works::AddFileToFileSet
          .call(file_set, new_content, :original_file, versioning: true)

        expect(storage_adapter.find_versions(id: id).first.io.read)
          .to eq "new content"
      end
    end
  end

  context 'when uploading with a file_set' do
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

    it 'adds a file to the file_set' do
      expect { storage_adapter.upload(resource: file_set, file: file, original_filename: file.original_filename) }
        .to change { Hyrax.query_service.find_by(id: file_set.id).file_ids.count }
        .from(0)
        .to(1)
    end

    it 'has a metadata node' do
      upload = storage_adapter.upload(resource: file_set, file: file, original_filename: file.original_filename)

      expect(Hyrax.custom_queries.find_file_metadata_by(id: upload.id))
        .to have_attributes original_filename: file.original_filename,
                            mime_type: 'image/png',
                            file_identifier: upload.id,
                            recorded_size: [file.size]
    end

    it 'can find content from its metadata node ' do
      upload = storage_adapter.upload(resource: file_set,
                                      file: file,
                                      original_filename: file.original_filename)
      metadata = Hyrax.custom_queries.find_file_metadata_by(id: upload.id)

      expect(storage_adapter.find_by(id: metadata.file_identifier).id)
        .to eq upload.id
    end

    it 'adds the file to the /files (LDP) container for the file set' do
      storage_adapter.upload(resource: file_set, file: file, original_filename: file.original_filename)

      af_file_set = FileSet.find(file_set.id.to_s)
      container_uri = af_file_set.uri / 'files/'
      file_id = af_file_set.resource.get_values(RDF::URI('http://pcdm.org/models#hasFile')).first.to_uri

      expect(file_id).to be_start_with container_uri
    end

    context 'with specific content' do
      let(:content) { "content\nwe\nwant\nto\twrite" }
      let(:file) do
        f = Tempfile.new('valkyrie-tmp')
        f.write content
        f.rewind
        f
      end

      it 'stores the content' do
        expect(storage_adapter.upload(resource: file_set, file: file, original_filename: 'content.txt').read)
          .to eq content
      end
    end

    context 'with existing files' do
      let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
      let(:new_use) { RDF::URI('http://example.com/ns/supplemental_file') }

      before do
        storage_adapter
          .upload(resource: file_set, file: file, original_filename: file.original_filename)
      end

      it 'can upload the file' do
        expect { storage_adapter.upload(resource: file_set, file: another_file, original_filename: 'file.txt', use: new_use) }
          .to change { Hyrax.query_service.find_by(id: file_set.id).file_ids.count }
          .from(1)
          .to(2)
      end
    end

    describe '#find_versions' do
      it 'gives an empty set when the id does not resolve' do
        expect(storage_adapter.find_versions(id: 'not_a_real_id'))
          .to be_empty
      end

      context 'with existing versions' do
        let(:another_file) { fixture_file_upload('/hyrax_generic_stub.txt') }
        let(:new_use) { RDF::URI('http://example.com/ns/supplemental_file') }

        let(:uploaded) do
          storage_adapter.upload(resource: file_set,
                                 file: file,
                                 original_filename: file.original_filename)
        end

        it 'finds existing versions' do
          uploaded

          expect(storage_adapter.find_versions(id: uploaded.id))
            .to contain_exactly(have_attributes(version_id: uploaded.id.to_s + '/fcr:versions/version1'))
        end

        it 'adds new versions for existing files' do
          uploaded

          expect { storage_adapter.upload_version(id: uploaded.id, file: another_file) }
            .to change { storage_adapter.find_versions(id: uploaded.id) }
            .to contain_exactly(have_attributes(version_id: uploaded.id.to_s + '/fcr:versions/version2'),
                                have_attributes(version_id: uploaded.id.to_s + '/fcr:versions/version1'))
        end
      end
    end
  end
end
