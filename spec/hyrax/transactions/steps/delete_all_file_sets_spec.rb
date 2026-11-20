# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::DeleteAllFileSets, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:user)      { FactoryBot.create(:user) }
  let(:work)      { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets) }

  describe '#call' do
    it 'fails without a user' do
      expect(step.call(work)).to be_failure
    end

    it 'gives success' do
      expect(step.call(work, user: user)).to be_success
    end

    it 'destroys each file_set' do
      member_ids = work.member_ids
      step.call(work, user: user)
      member_ids.each do |id|
        expect { Hyrax.query_service.find_by(id: id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end
    end

    context 'when the container shares one file_set.destroy transaction' do
      let(:shared_destroy) { Hyrax::Transactions::FileSetDestroy.new }

      before do
        allow(Hyrax::Transactions::Container).to receive(:[]).and_call_original
        allow(Hyrax::Transactions::Container).to receive(:[]).with('file_set.destroy').and_return(shared_destroy)
      end

      it 'leaves standalone file set destroys removing the file set from its work' do
        step.call(work, user: user)

        expect(shared_destroy.steps).to include('file_set.remove_from_work')
      end
    end

    context 'with a resource that is not saved' do
      let(:work) { FactoryBot.build(:hyrax_work) }

      it 'is a failure' do
        expect(step.call(work)).to be_failure
      end
    end
  end
end
