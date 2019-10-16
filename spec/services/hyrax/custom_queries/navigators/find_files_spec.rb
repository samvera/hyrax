RSpec.describe Hyrax::CustomQueries::Navigators::FindFiles do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:test_adapter).query_service }

  describe '#find_files' do
    subject { query_service.custom_queries.find_files(resource: fileset) }
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
end
