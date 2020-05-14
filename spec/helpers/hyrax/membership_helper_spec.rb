# frozen_string_literal: true

RSpec.describe Hyrax::MembershipHelper do
  describe '.member_of_collections_json' do
    context 'with a WorkForm' do
      let(:resource) { double(Hyrax::Forms::WorkForm) }

      it 'calls the form json implementation and returns its result' do
        expect(resource).to receive(:member_of_collections_json).and_return(:FAKE_JSON)
        expect(helper.member_of_collections_json(resource)).to eq :FAKE_JSON
      end
    end
  end
end
