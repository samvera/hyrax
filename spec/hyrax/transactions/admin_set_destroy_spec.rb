# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::AdminSetDestroy, valkyrie_adapter: :test_adapter do
  subject(:tx) { described_class.new }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_admin_set) }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(resource)).to be_success
    end

    context 'when the admin set is not empty' do
      let(:member_work) do
        FactoryBot.valkyrie_create(:hyrax_work, admin_set_id: resource.id)
      end

      before { member_work }

      it 'is a failure' do
        expect(tx.call(resource)).to be_failure
      end

      it 'gives useful error data' do
        expect(tx.call(resource).failure)
          .to include(contain_exactly(member_work))
      end
    end

    context 'with the default admin set' do
      it 'is a failure' do
        default_admin_set = Hyrax.config.default_admin_set
        expect(tx.call(default_admin_set)).to be_failure
      end
    end

    context 'with a permission template' do
      let(:resource_with_pt) { FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template) }

      describe '#call' do
        it 'is a success' do
          expect(tx.call(resource_with_pt)).to be_success
        end

        it 'will destroy the associated permission template' do
          # NOTE: We don't just check the PermissionTemplate count, because there are too many
          # possible PermissionTemplate-creating side effects to depend the "before" value
          tx.call(resource_with_pt)
          expect(Hyrax::PermissionTemplate.where(source_id: resource_with_pt.id)).not_to exist
        end

        it 'succeeds if the associated permission template has already been destroyed' do
          permission_template = Hyrax::PermissionTemplate.find_by!(source_id: resource_with_pt.id)
          permission_template.destroy!
          expect(tx.call(resource_with_pt)).to be_success
        end
      end
    end
  end
end
