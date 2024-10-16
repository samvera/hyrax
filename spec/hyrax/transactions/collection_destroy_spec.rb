# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::CollectionDestroy, valkyrie_adapter: :test_adapter do
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:user)     { FactoryBot.create(:user) }

  subject(:tx) do
    described_class.new
                   .with_step_args(
                     'collection_resource.delete' => { user: user },
                     'collection_resource.remove_from_membership' => { user: user }
                   )
  end

  describe '#call' do
    it 'is a success' do
      expect(tx.call(resource)).to be_success
    end

    context 'with a permission template' do
      let(:resource_with_pt) { FactoryBot.valkyrie_create(:hyrax_collection, :with_permission_template) }

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
