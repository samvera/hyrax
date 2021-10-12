# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SetCollectionTypeGid do
  subject(:step)   { described_class.new }
  let(:collection) { FactoryBot.build(:hyrax_collection, collection_type_gid: nil) }
  let(:change_set) { Hyrax::ChangeSet.for(collection) }

  describe '#call' do
    let(:default_collection_type_gid) do
      Hyrax::CollectionType
        .find_or_create_default_collection_type
        .to_global_id
    end

    it 'is success' do
      expect(step.call(change_set)).to be_success
    end

    context 'when a collection type gid is NOT passed in' do
      it 'sets the default collection type gid' do
        expect { step.call(change_set) }
          .to change { change_set.collection_type_gid }
          .to(default_collection_type_gid)
      end
    end

    context 'when a collection type gid is passed in' do
      let(:collection_type) { FactoryBot.create(:collection_type) }
      let(:collection_type_gid) { collection_type.to_global_id.to_s }

      it 'is success' do
        expect(step.call(change_set, collection_type_gid: collection_type_gid))
          .to be_success
      end

      it 'sets the collection type gid' do
        expect { step.call(change_set, collection_type_gid: collection_type_gid) }
          .to change { change_set.collection_type_gid }
          .to(collection_type_gid)
      end

      it 'does not override an existing collection type' do
        change_set.collection_type_gid = 'existing'

        expect { step.call(change_set, collection_type_gid: collection_type_gid) }
          .not_to change { change_set.collection_type_gid }
          .from('existing')
      end
    end
  end
end
