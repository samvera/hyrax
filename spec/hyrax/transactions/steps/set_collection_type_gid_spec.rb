# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SetCollectionTypeGid do
  subject(:step)   { described_class.new }
  let(:collection) { build(:hyrax_collection) }
  let(:change_set) { Hyrax::ChangeSet.for(collection) }

  describe '#call' do
    let(:default_collection_type_gid) { Hyrax::CollectionType.find_or_create_default_collection_type.to_global_id }

    it 'is success' do
      expect(step.call(change_set)).to be_success
    end

    context 'when a collection type gid is NOT passed in' do
      it 'sets the default collection type gid' do
        expect { step.call(change_set) }
          .not_to change { change_set.collection_type_gid }
          .from(default_collection_type_gid) # The default will always be assigned if one isn't give at create time.
      end
    end

    context 'when a collection type gid is passed in' do
      let(:collection_type) { create(:collection_type) }
      let(:collection_type_gid) { collection_type.to_global_id.to_s }

      it 'is success' do
        expect(step.call(change_set, collection_type_gid: collection_type_gid)).to be_success
      end

      it 'sets the collection type gid' do
        expect { step.call(change_set, collection_type_gid: collection_type_gid) }
          .to change { change_set.collection_type_gid }
          .from(default_collection_type_gid)
          .to(collection_type_gid)
      end
    end
  end
end
