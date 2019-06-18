RSpec.describe Hyrax::ActiveFedoraFinder do
  subject(:finder) { described_class.new }

  describe '.new' do
    let(:query_service) { :FAKE_QUERY_SERVICE }

    it 'sets the query service' do
      expect(described_class.new(query_service: query_service))
        .to have_attributes query_service: query_service
    end
  end

  describe '#find' do
    context 'when resource does not exist' do
      it 'raises object not found' do
        expect { finder.find('a_completely_fake_id') }
          .to raise_error ActiveFedora::ObjectNotFoundError
      end
    end

    context 'when resource is present' do
      let(:id)   { work.id }
      let(:work) { FactoryBot.create(:work) }

      it 'finds the resource' do
        expect(finder.find(id)).to eq work
      end
    end
  end
end
