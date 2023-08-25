# frozen_string_literal: true
RSpec.describe Hyrax::Actors::CollectionsMembershipActor, :active_fedora, skip: (!(Hyrax.config.collection_class < ActiveFedora::Base) || Hyrax.config.use_valkyrie?) do
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:curation_concern) { build(:work, user: user) }
  let(:attributes) { {} }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
      middleware.use RemoveCollectionActor
      middleware.use Hyrax::Actors::GenericWorkActor
    end
    stack.build(terminator)
  end

  describe 'the next actor' do
    let(:collection) { build(:collection_lw, with_permission_template: true) }
    let(:attributes) do
      {
        member_of_collections_attributes: { '0' => { id: '123' } },
        title: ['test']
      }
    end

    before do
      allow(Collection).to receive(:find).with('123').and_return(collection)
      allow(curation_concern).to receive(:member_of_collections=)
    end

    it 'does not receive the member_of_collections_attributes' do
      expect(terminator).to receive(:create).with(Hyrax::Actors::Environment) do |k|
        expect(k.attributes).to eq("title" => ["test"])
      end
      subject.create(env)
    end
  end

  describe 'create' do
    let(:collection) { create(:collection, collection_type_settings: [:discoverable], user: user, create_access: true) }
    let(:attributes) do
      {
        member_of_collections_attributes: { '0' => { id: collection.id } },
        title: ['test']
      }
    end

    it 'adds it to the collection' do
      expect(subject.create(env)).to be true
      expect(collection.reload.member_objects).to eq [curation_concern]
    end

    context 'when multiple membership checker returns a non-nil value' do
      before do
        allow(Hyrax::MultipleMembershipChecker).to receive(:new).and_return(checker)
        allow(checker).to receive(:check).and_return(error_message)
      end

      let(:checker) { double('checker') }
      let(:error_message) { 'Error: foo bar' }

      it 'adds an error and returns false' do
        expect(env.curation_concern.errors).to receive(:add).with(:collections, error_message)
        expect(subject.create(env)).to be false
        expect(curation_concern.member_of_collections).to be_empty
      end
    end

    context "when work is in user's own collection and destroy is passed" do
      let(:collection) { build(:collection_lw, user: user, title: ['A good title'], with_permission_template: true) }
      let(:attributes) do
        { member_of_collections_attributes: { '0' => { id: collection.id, _destroy: 'true' } } }
      end

      before do
        curation_concern.member_of_collections = [collection]
        curation_concern.save!
      end

      it "removes the work from that collection" do
        expect(subject.create(env)).to be true
        expect(curation_concern.member_of_collections).to eq []
      end
    end

    context "when working through Rails nested attribute scenarios" do
      let(:collection_to_remove) { create(:collection_lw, user: user, title: ['Already Member and Remove'], with_permission_template: true) }
      let(:collection_to_skip) { create(:collection_lw, user: user, title: ['Not a Member'], with_permission_template: true) }
      let(:collection_to_keep) { create(:collection_lw, user: user, title: ['Is a member and we want to keep'], with_permission_template: true) }
      let(:collection_to_add) { create(:collection_lw, user: user, title: ['Not a Member but want to add'], with_permission_template: true) }
      let(:attributes) do
        {
          member_of_collections_attributes: {
            '0' => { id: collection_to_remove.id, _destroy: 'true' }, # colleciton is a member and we're removing it
            '1' => { id: collection_to_skip.id, _destroy: 'true' }, # colleciton is a NOT member and is marked for deletion; This is a UI introduced option
            '2' => { id: collection_to_keep.id },
            '3' => { id: collection_to_add.id }
          }
        }
      end

      before do
        curation_concern.member_of_collections = [collection_to_remove, collection_to_keep]
        curation_concern.save!
      end

      it "removes the work from that collection" do
        expect(subject.create(env)).to be true
        expect(curation_concern.member_of_collections).to match_array [collection_to_keep, collection_to_add]
      end
    end

    context "when work is in another user's collection" do
      let(:other_user) { create(:user) }
      let(:other_collection) { build(:collection_lw, user: other_user, title: ['A good title'], with_permission_template: true) }

      before do
        curation_concern.member_of_collections = [other_collection]
        curation_concern.save!
      end

      it "doesn't remove the work from the other user's collection" do
        subject.create(env)
        expect(subject.create(env)).to be true
        expect(curation_concern.member_of_collections).to match_array [collection, other_collection]
      end
    end

    context "updates env" do
      let!(:collection_type) { create(:collection_type) }
      let!(:collection) { FactoryBot.create(:collection_lw, collection_type: collection_type, with_permission_template: true) }

      before do
        # Return the collection type instance which has stubs
        allow(Hyrax::CollectionType).to receive(:for).with(collection: collection).and_return(collection_type)
      end

      subject(:middleware) do
        stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use described_class
        end
        stack.build(terminator)
      end

      context "when share applies to works" do
        before do
          allow(collection_type).to receive(:share_applies_to_works).and_return(true)
        end

        context "and only one collection" do
          let(:attributes) do
            {
              member_of_collections_attributes: { '0' => { id: collection.id } },
              title: ['test']
            }
          end

          it "removes member_of_collections_attributes and adds collection_id to env" do
            expect(env.attributes).to have_key(:member_of_collections_attributes)
            expect(env.attributes[:member_of_collections_attributes].size).to eq 1
            expect(subject.create(env)).to be true
            expect(env.attributes).not_to have_key(:member_of_collections_attributes)
            expect(env.attributes).to have_key(:collection_id)
            expect(env.attributes[:collection_id]).to eq collection.id
          end
        end

        context "when more than one collection" do
          let(:collection2) { create(:collection_lw, with_permission_template: true) }
          let(:attributes) do
            {
              member_of_collections_attributes: {
                '0' => { id: collection.id },
                '1' => { id: collection2.id }
              },
              title: ['test']
            }
          end

          it "removes member_of_collections_attributes and does NOT add collection_id" do
            expect(env.attributes).to have_key(:member_of_collections_attributes)
            expect(env.attributes[:member_of_collections_attributes].size).to eq 2
            expect(subject.create(env)).to be true
            expect(env.attributes).not_to have_key(:member_of_collections_attributes)
            expect(env.attributes).not_to have_key(:collection_id)
          end
        end
      end

      context "when share does NOT apply to works" do
        before do
          allow(collection_type).to receive(:share_applies_to_new_works?).and_return(false)
          allow(Collection).to receive(:find).with(collection.id).and_return(collection)
          allow(Collection).to receive(:find).with([collection.id]).and_return([collection])
        end

        context "and only one collection" do
          let(:attributes) do
            {
              member_of_collections_attributes: { '0' => { id: collection.id } },
              title: ['test']
            }
          end

          it "removes member_of_collections_attributes and does NOT add collection_id" do
            expect(env.attributes).to have_key(:member_of_collections_attributes)
            expect(env.attributes[:member_of_collections_attributes].size).to eq 1
            expect(subject.create(env)).to be true
            expect(env.attributes).not_to have_key(:member_of_collections_attributes)
            expect(env.attributes).not_to have_key(:collection_id)
          end
        end
      end
    end
  end

  class RemoveCollectionActor < Hyrax::Actors::AbstractActor
    # The collection is normally removed by ApplyPermissionTemplateActor, but this test doesn't setup and call that actor.
    # So we are faking it here and removing it before the GenericWorkActor is called.  Otherwise, it tries to save a
    # property named collection_id which doesn't exist in GenericWork.
    def create(env)
      env.attributes.delete(:collection_id)
      next_actor.create(env)
    end
  end
end
