require 'valkyrie/specs/shared_specs/queries'

RSpec.describe Hyrax::Queries do
  let(:adapter)                  { described_class.metadata_adapter }
  let(:query_service)            { described_class.default_adapter }
  let(:persister)                { adapter.persister }

  before do
    described_class.metadata_adapter.persister.wipe!
  end

  it_behaves_like "a Valkyrie query provider"

  describe 'exists?' do
    let(:thing_that_exists)        { persister.save(resource: GenericWork.new(id: 'i_exist')) }
    let(:thing_that_used_to_exist) { persister.delete(resource: persister.save(resource: GenericWork.new(id: 'i_used_to_exist'))) }

    it 'knows the thing that exists exists' do
      expect(described_class.exists?(thing_that_exists.id)).to be true
    end

    it 'knows the thing that used to exist does not exist' do
      expect(described_class.exists?(thing_that_used_to_exist.id)).to be false
    end

    it 'knows the thing that does not exist does not exist' do
      expect(described_class.exists?(Valkyrie::ID.new('i_do_not_exist'))).to be false
    end
  end

  describe 'model specific finders' do
    let(:work) { create_for_repository(:work) }
    let(:file_set) { create_for_repository(:file_set) }
    let(:collection) { create_for_repository(:collection) }

    describe 'find_work' do
      it 'returns a work' do
        expect(described_class.find_work(id: work.id).id).to eq work.id
      end

      it 'raises error when not a work' do
        expect { described_class.find_work(id: file_set.id) }.to raise_error(Hyrax::ObjectNotFoundError)
      end
    end

    describe 'find_file_set' do
      it 'returns a file set' do
        expect(described_class.find_file_set(id: file_set.id).id).to eq file_set.id
      end

      it 'raises error when not a file set' do
        expect { described_class.find_file_set(id: work.id) }.to raise_error(Hyrax::ObjectNotFoundError)
      end
    end

    describe 'find_collection' do
      it 'returns a collection' do
        expect(described_class.find_collection(id: collection.id).id).to eq collection.id
      end

      it 'raises error when not a collection' do
        expect { described_class.find_collection(id: file_set.id) }.to raise_error(Hyrax::ObjectNotFoundError)
      end
    end
  end
end
