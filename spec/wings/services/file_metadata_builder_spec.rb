# frozen_string_literal: true
require 'wings_helper'
require 'wings/services/file_metadata_builder'

RSpec.describe Wings::FileMetadataBuilder, :clean_repo do
  subject(:builder) do
    described_class.new(storage_adapter: Hyrax.storage_adapter,
                        persister: Hyrax.persister)
  end

  let(:af_file_set)   { create(:file_set, id: 'fileset_id') }
  let!(:file_set)     { af_file_set.valkyrie_resource }

  let(:io_wrapper)    { instance_double(JobIoWrapper, file: file, original_name: original_name, mime_type: mime_type, size: file.size) }
  let(:file)          { File.open(File.join(fixture_path, original_name)) }
  let(:original_name) { 'sample-file.pdf' }
  let(:mime_type)     { 'application/pdf' }
  let(:use)           { Hyrax::FileMetadata::Use::ORIGINAL_FILE }

  let(:original_file_metadata) do
    Hyrax::FileMetadata.new(label: original_name,
                            original_filename: original_name,
                            mime_type: mime_type,
                            type: [use])
  end

  describe '#create(io_wrapper:, file_metadata:, file_set:)' do
    it 'creates file metadata' do
      built_file_metadata = builder.create(io_wrapper: io_wrapper, file_metadata: original_file_metadata, file_set: file_set)
      expect(built_file_metadata).to be_kind_of Hyrax::FileMetadata
      expect(built_file_metadata.original_file?).to be true
      expect(built_file_metadata.file_set_id.id).to eq file_set.id.id
      expect(built_file_metadata.label).to contain_exactly(original_name)
      expect(built_file_metadata.original_filename).to contain_exactly(original_name)
      expect(built_file_metadata.mime_type).to eq mime_type
      expect(built_file_metadata.type).to contain_exactly(use)
    end
  end
end
