# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::WorkCreate do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { build(:hyrax_work) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved work' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    it 'sets the default admin set' do
      expect(tx.call(change_set).value!)
        .to have_attributes admin_set_id: Valkyrie::ID.new('admin_set/default')
    end

    context 'when an admin set is already assigned to the work' do
      let(:admin_set) { valkyrie_create(:hyrax_admin_set) }
      let(:resource) { build(:hyrax_work, admin_set_id: admin_set.id) }

      it 'keeps the existing admin set' do
        expect(tx.call(change_set).value!)
          .to have_attributes admin_set_id: admin_set.id
      end
    end

    context 'when providing a depositor' do
      let(:user) { FactoryBot.create(:user) }

      it 'sets the given user as the depositor' do
        tx.with_step_args('change_set.set_user_as_depositor' => { user: user })

        expect(tx.call(change_set).value!)
          .to have_attributes depositor: user.user_key
      end
    end

    context 'when adding to collections' do
      let(:collections) do
        [FactoryBot.valkyrie_create(:hyrax_collection),
         FactoryBot.valkyrie_create(:hyrax_collection)]
      end

      let(:collection_ids) { collections.map(&:id) }

      it 'adds to the collections' do
        tx.with_step_args('change_set.add_to_collections' => { collection_ids: collection_ids })

        expect(tx.call(change_set).value!)
          .to have_attributes member_of_collection_ids: contain_exactly(*collection_ids)
      end
    end
  end
end
