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
  end
end
