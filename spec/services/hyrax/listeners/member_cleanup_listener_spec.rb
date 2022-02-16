# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Listeners::MemberCleanupListener do
  subject(:listener) { described_class.new }
  let(:data)         { { collection: collection, user: user } }
  let(:event)        { Dry::Events::Event.new(event_type, data) }
  let(:user)         { FactoryBot.create(:user) }
  let(:spy_listener) { Hyrax::Specs::SpyListener.new }

  before { Hyrax.publisher.subscribe(spy_listener) }
  after  { Hyrax.publisher.unsubscribe(spy_listener) }

  describe '#on_object_deleted' do
    let(:data)         { { object: work, user: user } }
    let(:event_type)   { :on_object_deleted }
    let(:work)         { FactoryBot.valkyrie_create(:hyrax_work, member_ids: [file_set.id]) }
    let(:file_set)     { FactoryBot.valkyrie_create(:hyrax_file_set) }

    it 'removes child file set objects' do
      expect { listener.on_object_deleted(event) }
        .to change { Hyrax.custom_queries.find_child_file_sets(resource: event[:object]).size }
        .from(1)
        .to(0)
    end

    it 'publishes events' do
      listener.on_object_deleted(event)
      expect(spy_listener.object_deleted&.payload)
        .to include(id: file_set.id, object: file_set, user: user)
    end
  end

  describe '#on_collection_deleted' do
    let(:collection)   { FactoryBot.valkyrie_create(:hyrax_collection) }
    let(:data)         { { collection: collection, user: user } }
    let(:event_type)   { :on_collection_deleted }
    let(:work)         { FactoryBot.valkyrie_create(:monograph, member_of_collection_ids: [collection.id]) }

    before do
      work
    end

    it 'removes collection references from member objects' do
      expect { listener.on_collection_deleted(event) }
        .to change { Hyrax.custom_queries.find_members_of(collection: event[:collection]).size }
        .from(1)
        .to(0)
    end

    it 'publishes events' do
      listener.on_collection_deleted(event)
      expect(spy_listener.collection_membership_updated&.payload)
        .to include(collection: collection, user: user)
    end
  end
end
