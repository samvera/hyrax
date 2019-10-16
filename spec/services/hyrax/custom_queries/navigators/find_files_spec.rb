RSpec.describe Hyrax::CustomQueries::Navigators::FindFiles do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:test_adapter).query_service }

  describe '#find_files' do
    subject { query_service.custom_queries.find_files(file_set: fileset) }
    context 'when files exist' do
      let!(:file_metadata1) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:file_metadata2) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:fileset) { FactoryBot.create_using_test_adapter(:hyrax_pcdm_file_set, files: [file_metadata1, file_metadata2]) }
      it 'returns file metadata resource' do
        expect(subject).to be_a Array
        expect(subject.size).to eq 2
        expect(subject.map(&:id).map(&:to_s)).to match_array [file_metadata1.id.to_s, file_metadata2.id.to_s]
        expect(subject.first).to be_a Hyrax::FileMetadata
      end
    end

    context 'when files do not exist' do
      let!(:fileset) { FactoryBot.build(:hyrax_pcdm_file_set) }
      it 'returns an empty array' do
        expect(subject).to eq []
      end
    end
  end

  describe '#find_original_file' do
    subject { query_service.custom_queries.find_original_file(file_set: fileset) }
    context 'when original file exists' do
      let!(:original_file) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:fileset) { FactoryBot.create_using_test_adapter(:hyrax_pcdm_file_set, files: [original_file], original_file: original_file) }
      it 'returns file metadata resource' do
        expect(subject).to be_a Hyrax::FileMetadata
        expect(subject.id.to_s).to eq original_file.id.to_s
      end
    end

    context 'when files do not exist' do
      let!(:fileset) { FactoryBot.build(:hyrax_pcdm_file_set) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "File set's original file is blank"
      end
    end

    context 'when file_set does not respond to original file' do
      let!(:fileset) { FactoryBot.build(:hyrax_resource) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "Hyrax::Resource is not a `Hydra::PcdmFileSet` implementer"
      end
    end
  end

  describe '#find_extracted_text' do
    subject { query_service.custom_queries.find_extracted_text(file_set: fileset) }
    context 'when extracted text exists' do
      let!(:extracted_text) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:fileset) { FactoryBot.create_using_test_adapter(:hyrax_pcdm_file_set, files: [extracted_text], extracted_text: extracted_text) }
      it 'returns file metadata resource' do
        expect(subject).to be_a Hyrax::FileMetadata
        expect(subject.id.to_s).to eq extracted_text.id.to_s
      end
    end

    context 'when files do not exist' do
      let!(:fileset) { FactoryBot.build(:hyrax_pcdm_file_set) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "File set's extracted text is blank"
      end
    end

    context 'when file_set does not respond to extracted text' do
      let!(:fileset) { FactoryBot.build(:hyrax_resource) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "Hyrax::Resource is not a `Hydra::PcdmFileSet` implementer"
      end
    end
  end

  describe '#find_thumbnail' do
    subject { query_service.custom_queries.find_thumbnail(file_set: fileset) }
    context 'when thumbnail exists' do
      let!(:thumbnail) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:fileset) { FactoryBot.create_using_test_adapter(:hyrax_pcdm_file_set, files: [thumbnail], thumbnail: thumbnail) }
      it 'returns file metadata resource' do
        expect(subject).to be_a Hyrax::FileMetadata
        expect(subject.id.to_s).to eq thumbnail.id.to_s
      end
    end

    context 'when files do not exist' do
      let!(:fileset) { FactoryBot.build(:hyrax_pcdm_file_set) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "File set's thumbnail is blank"
      end
    end

    context 'when file_set does not respond to thumbnail' do
      let!(:fileset) { FactoryBot.build(:hyrax_resource) }
      it 'raises error' do
        expect { subject }.to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "Hyrax::Resource is not a `Hydra::PcdmFileSet` implementer"
      end
    end
  end
end
