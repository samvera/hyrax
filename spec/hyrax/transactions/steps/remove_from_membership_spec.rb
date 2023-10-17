# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Transactions::Steps::RemoveFromMembership, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:user)         { FactoryBot.create(:user) }
  let(:collection)   { FactoryBot.valkyrie_create(:hyrax_collection) }
  let(:work)         { FactoryBot.valkyrie_create(:monograph, member_of_collection_ids: [collection.id]) }
  let(:spy_listener) { Hyrax::Specs::SpyListener.new }

  describe '#call' do
    before do
      work
      Hyrax.publisher.subscribe(spy_listener)
    end
    after { Hyrax.publisher.unsubscribe(spy_listener) }

    it 'fails without a user' do
      expect(step.call(collection)).to be_failure
    end

    it 'gives success' do
      expect(step.call(collection, user: user)).to be_success
    end

    it 'removes collection references from member objects' do
      expect { step.call(collection, user: user) }
        .to change { Hyrax.custom_queries.find_members_of(collection: collection).size }
        .from(1)
        .to(0)
    end

    it 'publishes events' do
      expect { step.call(collection, user: user) }
        .to change { spy_listener.collection_membership_updated&.payload }
        .to match(collection: collection, user: user)
    end
  end
end
