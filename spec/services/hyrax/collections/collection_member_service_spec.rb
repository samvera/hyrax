# frozen_string_literal: true
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::Collections::CollectionMemberService, clean_repo: true do
  subject(:builder) do
    described_class.new(scope: scope, collection: nestable_collection, params: { "id" => nestable_collection.id.to_s })
  end

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }
  let!(:subcollection) { create(:public_collection_lw, member_of_collections: [nestable_collection], collection_type_settings: [:nestable]) }

  let!(:nestable_collection) { create(:public_collection_lw, collection_type_settings: [:nestable]) }
  let!(:work1) { create(:generic_work, member_of_collections: [nestable_collection]) }
  let!(:work2) { create(:generic_work) }
  let!(:work3) { create(:generic_work, member_of_collections: [nestable_collection]) }

  describe '#available_member_subcollections' do
    it 'returns the members that are collections' do
      ids = builder.available_member_subcollections.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(subcollection.id)
    end
  end

  describe '#available_member_works' do
    it 'returns the members that are collections' do
      ids = builder.available_member_works.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end

  describe '#available_member_work_ids' do
    it 'returns the members ids that are works' do
      ids = builder.available_member_work_ids.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end

  let(:custom_query_service) { Hyrax.custom_queries }
  let(:user) { create(:user) }
  let(:listener) { Hyrax::Specs::SpyListener.new }

  before { Hyrax.publisher.subscribe(listener) }
  after { Hyrax.publisher.unsubscribe(listener) }

  describe '.member?' do
    let(:non_member) { FactoryBot.valkyrie_create(:hyrax_work) }
    context 'when no members' do
      let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
      it 'returns false' do
        expect(described_class.member?(collection: collection, member: non_member)).to eq false
      end
    end
    context 'when has members' do
      let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
      let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: [work1, work2]) }
      it "returns false if member isn't in member set" do
        expect(described_class.member?(collection: collection, member: non_member)).to eq false
      end
      it "returns true if member is in member set" do
        expect(described_class.member?(collection: collection, member: work1)).to eq true
      end
    end
  end

  describe '.add_members_by_ids' do
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:new_member_ids) { [work1.id, work2.id] }

    before { described_class.add_members_by_ids(collection: collection, new_member_ids: new_member_ids, user: user) }

    context 'when no members' do
      it "updates the collection member set to contain only the new members" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array new_member_ids
      end
    end
    context 'when has members' do
      let(:existing_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:existing_members) { [existing_work] }
      context 'and one of the new members already exists in the member set' do
        let(:new_member_ids) { [work1.id, work2.id, existing_work.id] }
        it "updates the collection member set adding only resources not already in the member set" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array new_member_ids
        end
      end
      context 'and none of the new members exist in the member set' do
        it "updates the collection member set adding the new members" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids + new_member_ids
        end
      end
    end
  end

  describe '.add_members' do
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:new_members) { [work1, work2] }
    let(:new_member_ids) { [work1.id, work2.id] }

    before { described_class.add_members(collection: collection, new_members: new_members, user: user) }

    context 'when no members' do
      it "updates the collection member set to contain only the new members" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array new_member_ids
      end
    end
    context 'when has members' do
      let(:existing_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:existing_members) { [existing_work] }
      context 'and a members already exists in the member set' do
        let(:new_members) { [work1, work2, existing_work] }
        let(:new_member_ids) { [work1.id, work2.id, existing_work.id] }
        it "updates the collection member set adding only resources not already in the member set" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array new_member_ids
        end
      end
      context 'and none of the new members exist in the member set' do
        it "updates the collection member set adding the new members" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids + new_member_ids
        end
      end
    end
  end

  describe '.add_member_by_id' do
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:new_member_id) { work1.id }

    before { described_class.add_member_by_id(collection: collection, new_member_id: new_member_id, user: user) }

    context 'when no members' do
      it "updates the collection member set to contain only the new members" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [new_member_id]
      end
    end
    context 'when has members' do
      let(:existing_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:existing_members) { [existing_work] }
      context 'and the new member already exists in the member set' do
        let(:new_member_id) { existing_work.id }
        it "the collection member set remains unchanged" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
        end
      end
      context 'and the new member does not exist in the member set' do
        it "updates the collection member set adding the new member" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids + [new_member_id]
        end
      end
    end
  end

  describe '.add_member' do
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:new_member) { work1 }

    before { described_class.add_member(collection: collection, new_member: new_member, user: user) }

    context 'when no members' do
      it "updates the collection member set to contain only the new members" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [new_member.id]
      end
    end
    context 'when has members' do
      let(:existing_work) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:existing_members) { [existing_work] }
      context 'and the new member already exists in the member set' do
        let(:new_member) { existing_work }
        it "the collection member set remains unchanged" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
        end
      end
      context 'and the new member does not exist in the member set' do
        it "updates the collection member set adding the new member" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids + [new_member.id]
        end
        it "publishes metadata updated event for member" do
          updated_work = described_class.add_member(collection: collection, new_member: new_member, user: user)
          expect(listener.object_metadata_updated&.payload)
            .to eq object: updated_work, user: user
        end
      end
    end
  end

  describe '.remove_members_by_ids' do
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [work1, work2] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:members_to_remove_ids) { [work1.id, work2.id] }

    context 'when no members' do
      let(:existing_members) { [] }
      it "collection member remains empty" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
        described_class.remove_members_by_ids(collection: collection, member_ids: members_to_remove_ids, user: user)
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
      end
    end
    context 'when has members' do
      context 'and none of the members to remove exist in the member set' do
        let(:non_existing_work1) { FactoryBot.valkyrie_create(:hyrax_work) }
        let(:non_existing_work2) { FactoryBot.valkyrie_create(:hyrax_work) }
        let(:members_to_remove_ids) { [non_existing_work1.id, non_existing_work2.id] }
        it "collection members remain unchanged" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_members_by_ids(collection: collection, member_ids: members_to_remove_ids, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
        end
      end
      context 'and the members to remove exist in the member set' do
        let(:work3) { FactoryBot.valkyrie_create(:hyrax_work) }
        let(:existing_members) { [work1, work2, work3] }
        it "updates the collection member set removing the members" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_members_by_ids(collection: collection, member_ids: members_to_remove_ids, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [work3.id]
        end
      end
    end

    describe '.remove_members' do
      let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
      let(:existing_members) { [work1, work2] }
      let(:existing_member_ids) { existing_members.map(&:id) }
      let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
      let(:members_to_remove) { [work1, work2] }

      context 'when no members' do
        let(:existing_members) { [] }
        it "collection member remains empty" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
          described_class.remove_members(collection: collection, members: members_to_remove, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
        end
      end
      context 'when has members' do
        context 'and none of the members to remove exist in the member set' do
          let(:non_existing_work1) { FactoryBot.valkyrie_create(:hyrax_work) }
          let(:non_existing_work2) { FactoryBot.valkyrie_create(:hyrax_work) }
          let(:members_to_remove) { [non_existing_work1, non_existing_work2] }
          it "collection members remain unchanged" do
            expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
            described_class.remove_members(collection: collection, members: members_to_remove, user: user)
            expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          end
        end
        context 'and the members to remove exist in the member set' do
          let(:work3) { FactoryBot.valkyrie_create(:hyrax_work) }
          let(:existing_members) { [work1, work2, work3] }
          it "updates the collection member set removing the members" do
            expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
            described_class.remove_members(collection: collection, members: members_to_remove, user: user)
            expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [work3.id]
          end
        end
      end
    end
  end

  describe '.remove_member_by_id' do
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [work1, work2] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:member_to_remove_id) { work1.id }

    context 'when no members' do
      let(:existing_members) { [] }
      it "collection member remains empty" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
        described_class.remove_member_by_id(collection: collection, member_id: member_to_remove_id, user: user)
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
      end
    end
    context 'when has members' do
      context 'and the member to remove does not exist in the member set' do
        let(:non_existing_work1) { FactoryBot.valkyrie_create(:hyrax_work) }
        let(:member_to_remove_id) { non_existing_work1.id }
        it "collection members remain unchanged" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_member_by_id(collection: collection, member_id: member_to_remove_id, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
        end
      end
      context 'and the member to remove exists in the member set' do
        it "updates the collection member set removing the members" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_member_by_id(collection: collection, member_id: member_to_remove_id, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [work2.id]
        end
      end
    end
  end

  describe '.remove_member' do
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, members: existing_members) }
    let(:existing_members) { [work1, work2] }
    let(:existing_member_ids) { existing_members.map(&:id) }
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work) }
    let(:member_to_remove) { work1 }

    context 'when no members' do
      let(:existing_members) { [] }
      it "collection member remains empty" do
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
        described_class.remove_member(collection: collection, member: member_to_remove, user: user)
        expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to eq []
      end
    end
    context 'when has members' do
      context 'and the member to remove does not exist in the member set' do
        let(:non_existing_work1) { FactoryBot.valkyrie_create(:hyrax_work) }
        let(:member_to_remove) { non_existing_work1 }
        it "collection members remain unchanged" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_member(collection: collection, member: member_to_remove, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
        end
      end
      context 'and the member to remove exists in the member set' do
        it "updates the collection member set removing the members" do
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array existing_member_ids
          described_class.remove_member(collection: collection, member: member_to_remove, user: user)
          expect(custom_query_service.find_members_of(collection: collection).map(&:id)).to match_array [work2.id]
        end
        it "publishes metadata updated event for member" do
          updated_work = described_class.remove_member(collection: collection, member: member_to_remove, user: user)
          expect(listener.object_metadata_updated&.payload)
            .to eq object: updated_work, user: user
        end
      end
    end
  end
end
