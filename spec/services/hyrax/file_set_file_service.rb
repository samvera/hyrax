# frozen_string_literal: true
RSpec.describe Hyrax::FileSetFileService do
  describe '#original_file' do
    let(:original_file) { FactoryBot.valkyrie_create(:hyrax_file_metadata) }
    let(:other_file) { FactoryBot.valkyrie_create(:hyrax_file_metadata, use: :thumbnail_file) }

    context 'when an original file is set' do
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [other_file, original_file], original_file: original_file) }
      let(:file_service) { Hyrax::FileSetFileService.new(file_set: fileset) }

      it 'returns the original file' do
        expect(fileset.original_file_id).to eq original_file.id
        expect(file_service.original_file.id).to eq original_file.id
      end
    end

    context 'when an original file is present but not set' do
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [other_file, original_file]) }
      let(:file_service) { Hyrax::FileSetFileService.new(file_set: fileset) }

      it 'returns the original file' do
        expect(fileset.original_file_id).to be_nil
        expect(file_service.original_file.id).to eq original_file.id
      end
    end

    context 'when no original file is present' do
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [other_file]) }
      let(:file_service) { Hyrax::FileSetFileService.new(file_set: fileset) }

      it 'returns the first file as a fallback' do
        expect(other_file.type).not_to eq Hyrax::FileMetadata::Use::ORIGINAL_FILE
        expect(file_service.original_file.id).to eq other_file.id
      end
    end
  end
end
