# frozen_string_literal: true
RSpec.describe Hyrax::CustomQueries::Navigators::FindFiles, valkyrie_adapter: :test_adapter do
  subject(:query_handler) do
    described_class.new(query_service: Hyrax.query_service)
  end

  describe '#find_files' do
    context 'when files exist' do
      let(:file_metadata1) { FactoryBot.valkyrie_create(:hyrax_file_metadata) }
      let(:file_metadata2) { FactoryBot.valkyrie_create(:hyrax_file_metadata) }
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [file_metadata1, file_metadata2]) }

      it 'returns file metadata resource' do
        expect(query_handler.find_files(file_set: fileset).map(&:id).map(&:to_s))
          .to match_array [file_metadata1.id.to_s, file_metadata2.id.to_s]
      end
    end

    context 'when files do not exist' do
      let(:fileset) { FactoryBot.build(:hyrax_file_set) }

      it 'returns an empty array' do
        expect(query_handler.find_files(file_set: fileset)).to be_empty
      end
    end
  end

  describe '#find_original_file' do
    context 'when original file exists' do
      let(:original_file) { FactoryBot.valkyrie_create(:hyrax_file_metadata, use: :original_file) }
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [original_file]) }

      it 'returns file metadata resource' do
        expect(query_handler.find_original_file(file_set: fileset).id.to_s).to eq original_file.id.to_s
      end
    end

    context 'when files do not exist' do
      let(:fileset) { FactoryBot.build(:hyrax_file_set) }

      it 'raises error' do
        expect { query_handler.find_original_file(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when resource does not respond file_ids' do
      let(:fileset) { FactoryBot.build(:hyrax_resource) }

      it 'raises error' do
        expect { query_handler.find_original_file(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end

  describe '#find_extracted_text' do
    context 'when extracted text exists' do
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [extracted_text]) }

      let(:extracted_text) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata, use: :extracted_file)
      end

      it 'returns file metadata resource' do
        expect(query_handler.find_extracted_text(file_set: fileset).id.to_s).to eq extracted_text.id.to_s
      end
    end

    context 'when files do not exist' do
      let(:fileset) { FactoryBot.build(:hyrax_file_set) }

      it 'raises error' do
        expect { query_handler.find_extracted_text(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when resource does not respond file_ids' do
      let(:fileset) { FactoryBot.build(:hyrax_resource) }

      it 'raises error' do
        expect { query_handler.find_extracted_text(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end

  describe '#find_thumbnail' do
    context 'when thumbnail exists' do
      let(:fileset) { FactoryBot.valkyrie_create(:hyrax_file_set, files: [thumbnail], thumbnail: thumbnail) }

      let(:thumbnail) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata, use: :thumbnail_file)
      end

      it 'returns file metadata resource' do
        expect(query_handler.find_thumbnail(file_set: fileset).id.to_s).to eq thumbnail.id.to_s
      end
    end

    context 'when files do not exist' do
      let(:fileset) { FactoryBot.build(:hyrax_file_set) }

      it 'raises error' do
        expect { query_handler.find_thumbnail(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when resource does not respond file_ids' do
      let(:fileset) { FactoryBot.build(:hyrax_resource) }

      it 'raises error' do
        expect { query_handler.find_thumbnail(file_set: fileset) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end
end
