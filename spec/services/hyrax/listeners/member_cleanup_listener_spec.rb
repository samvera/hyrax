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
    let(:data)         { { object: child_work, user: user } }
    let(:event_type)   { :on_object_deleted }
    let(:child_work)   { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:parent_work)  { FactoryBot.valkyrie_create(:hyrax_work) }

    before do
      parent_work.member_ids += [child_work.id]
      Hyrax.persister.save(resource: parent_work)
    end

    it "removes the child work id from the parent works' #member_ids" do
      expect(Hyrax.query_service.find_by(id: parent_work.id).member_ids).to be_present
      listener.on_object_deleted(event)
      expect(Hyrax.query_service.find_by(id: parent_work.id).member_ids).to be_empty
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

    xit 'removes collection references from member objects' do
      expect { listener.on_collection_deleted(event) }
        .to change { Hyrax.custom_queries.find_members_of(collection: event[:collection]).size }
        .from(1)
        .to(0)
    end

    xit 'publishes events' do
      listener.on_collection_deleted(event)
      expect(spy_listener.collection_membership_updated&.payload)
        .to include(collection: collection, user: user)
    end
  end
end
