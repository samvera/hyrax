RSpec.describe Hyrax::CustomQueries::FindFileMetadata do
  let(:query_service) { Valkyrie::MetadataAdapter.find(:test_adapter).query_service }
  subject(:query_handler) { described_class.new(query_service: query_service) }

  describe '.queries' do
    it 'lists queries' do
      expect(described_class.queries).to eq [:find_file_metadata_by,
                                             :find_file_metadata_by_alternate_identifier,
                                             :find_many_file_metadata_by_ids]
    end
  end

  describe '.find_file_metadata_by' do
    context 'when id is for a file metadata resource' do
      let!(:file_metadata1) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:file_metadata2) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      it 'returns file metadata resource' do
        expect(query_handler.find_file_metadata_by(id: file_metadata1.id).id.to_s).to eq file_metadata1.id.to_s
      end
    end

    context 'when id for a non-file metadata resource' do
      let!(:resource) { FactoryBot.create_using_test_adapter(:hyrax_resource) }
      it 'raises ObjectNotFound' do
        expect { query_handler.find_file_metadata_by(id: resource.id) }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "Result type Hyrax::Resource for id #{resource.id} is not a `Hyrax::FileMetadata`"
      end
    end

    context 'when id is invalid' do
      it 'raises ObjectNotFound' do
        expect { query_handler.find_file_metadata_by(id: 'BOGUS') }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end

  describe '.find_file_metadata_by_alternate_identifier' do
    context 'when file exists' do
      let!(:file_metadata1) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata, alternate_ids: ['fm1']) }
      let!(:file_metadata2) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata, alternate_ids: ['fm2']) }
      it 'returns file metadata resource' do
        expect(query_handler.find_file_metadata_by_alternate_identifier(alternate_identifier: 'fm2').id.to_s).to eq file_metadata2.id.to_s
      end
    end

    context 'when id for a non-file metadata resource' do
      let!(:resource) { FactoryBot.create_using_test_adapter(:hyrax_resource, alternate_ids: ['r1']) }
      it 'raises ObjectNotFound' do
        expect { query_handler.find_file_metadata_by_alternate_identifier(alternate_identifier: 'r1').id.to_s }
          .to raise_error ::Valkyrie::Persistence::ObjectNotFoundError, "Result type Hyrax::Resource for alternate_identifier #{resource.alternate_ids.first} is not a `Hyrax::FileMetadata`"
      end
    end

    context 'when id is invalid' do
      it 'raises ObjectNotFound' do
        expect { query_handler.find_file_metadata_by_alternate_identifier(alternate_identifier: 'BOGUS') }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end
  end

  describe '.find_many_file_metadata_by_ids' do
    context 'when files exists' do
      let!(:file_metadata1) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:file_metadata2) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let(:ids) { [file_metadata1.id, file_metadata2.id] }
      it 'returns file metadata resources' do
        expect(query_handler.find_many_file_metadata_by_ids(ids: ids).map { |fm| fm.id.to_s }).to match_array(ids.map(&:to_s))
      end
    end

    context 'when some ids are for non-file metadata resources' do
      let!(:file_metadata1) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:file_metadata2) { FactoryBot.create_using_test_adapter(:hyrax_file_metadata) }
      let!(:non_file_metadata_resource) { FactoryBot.create_using_test_adapter(:hyrax_resource) }
      let!(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [file_metadata1.id, file_metadata2.id, non_file_metadata_resource.id, non_existent_id] }
      it 'only includes file metadata resources' do
        expect(query_handler.find_many_file_metadata_by_ids(ids: ids).map { |fm| fm.id.to_s }).to match_array [file_metadata1.id.to_s, file_metadata2.id.to_s]
      end
    end

    context 'when not passed any valid ids' do
      let!(:non_file_metadata_resource) { FactoryBot.create_using_test_adapter(:hyrax_resource) }
      let!(:non_existent_id) { ::Valkyrie::ID.new('BOGUS') }
      let(:ids) { [non_file_metadata_resource.id, non_existent_id] }
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
end
