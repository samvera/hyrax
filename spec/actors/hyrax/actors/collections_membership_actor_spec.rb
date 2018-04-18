RSpec.describe Hyrax::Actors::CollectionsMembershipActor do
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
    let(:collection) { create(:collection, create_access: true) }
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
      let(:collection) { create(:collection, user: user, title: ['A good title'], create_access: true) }
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

    context "when work is in another user's collection" do
      let(:other_user) { create(:user) }
      let(:other_collection) { create(:collection, user: other_user, title: ['A good title'], create_access: true) }

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

    context 'when passing `member_of_collection_ids`' do
      let(:attributes) { { member_of_collection_ids: [collection.id], title: ['test'] } }

      it 'adds it to the collection' do
        skip 'this behavior past its deprecation sunset time and can be removed' if
          Hyrax::VERSION.split('.').first.to_i >= 3

        expect(subject.create(env)).to be true
        expect(collection.reload.member_objects).to eq [curation_concern]
      end

      context 'when it is empty' do
        let(:attributes) { { member_of_collection_ids: [], title: ['test'] } }

        it 'does not add it to a collection' do
          skip 'this behavior past its deprecation sunset time and can be removed' if
            Hyrax::VERSION.split('.').first.to_i >= 3

          expect(subject.create(env)).to be true
          expect(collection.reload.member_objects).to eq []
        end
      end

      context 'when it is an empty string' do
        let(:attributes) { { member_of_collection_ids: '', title: ['test'] } }

        it 'does not add it to a collection' do
          skip 'this behavior past its deprecation sunset time and can be removed' if
            Hyrax::VERSION.split('.').first.to_i >= 3

          expect(subject.create(env)).to be true
          expect(collection.reload.member_objects).to eq []
        end
      end

      context "when work is in user's own collection" do
        let(:attributes) { { member_of_collection_ids: [] } }

        it "removes the work from that collection" do
          skip 'this behavior past its deprecation sunset time and can be removed' if
            Hyrax::VERSION.split('.').first.to_i >= 3

          expect(subject.create(env)).to be true
          expect(collection.reload.member_objects).to be_empty
        end
      end

      describe "when work is in another user's collection" do
        let(:other_user)    { create(:user) }
        let(:collection)    { create(:collection, user: other_user, title: ['A good title']) }
        let(:my_collection) { create(:collection, title: ['My good title']) }

        let(:attributes) { { member_of_collection_ids: [my_collection.id] } }

        before do
          curation_concern.member_of_collections = [collection]
          curation_concern.save!
        end

        it "doesn't remove the work from the other user's collection" do
          skip 'this behavior past its deprecation sunset time and can be removed' if
            Hyrax::VERSION.split('.').first.to_i >= 3

          expect(subject.create(env)).to be true
          expect(curation_concern.member_of_collections)
            .to contain_exactly(collection, my_collection)
        end
      end
    end

    context "updates env" do
      let!(:collection_type) { create(:collection_type) }
      let!(:collection) { create(:collection, collection_type_gid: collection_type.gid, create_access: true) }

      subject(:middleware) do
        stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
          middleware.use described_class
        end
        stack.build(terminator)
      end

      context "when share applies to works" do
        before do
          allow(collection.collection_type).to receive(:share_applies_to_works).and_return(true)
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
          let(:collection2) { create(:collection, create_access: true) }
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
          allow(collection.collection_type).to receive(:share_applies_to_new_works?).and_return(false)
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

          it "removes member_of_collection_ids and does NOT add collection_id" do
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

  context 'when old style env parameter' do
    describe 'create' do
      let(:collection) { create(:collection) }
      let(:attributes) do
        { member_of_collection_ids: [collection.id], title: ['test'] }
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

      context "when work is in user's own collection" do
        let(:collection) { create(:collection, user: user, title: ['A good title']) }
        let(:attributes) { { member_of_collection_ids: [] } }

        before do
          subject.create(Hyrax::Actors::Environment.new(curation_concern, ability,
                                                        member_of_collection_ids: [collection.id], title: ['test']))
        end

        it "removes the work from that collection" do
          expect(subject.create(env)).to be true
          expect(curation_concern.member_of_collections).to eq []
        end
      end

      context "when work is in another user's collection" do
        let(:other_user) { create(:user) }
        let(:collection) { create(:collection, user: other_user, title: ['A good title']) }

        it "doesn't remove the work from that collection" do
          subject.create(env)
          expect(subject.create(env)).to be true
          expect(curation_concern.member_of_collections).to eq [collection]
        end
      end

      context "updates env" do
        let(:collection) do
          create(:collection, collection_type_settings: [:discoverable, :sharable])
        end

        subject(:middleware) do
          stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
            middleware.use described_class
          end
          stack.build(terminator)
        end

        context "when only one collection" do
          let(:attributes) do
            { member_of_collection_ids: [collection.id], title: ['test'] }
          end

          it "removes member_of_collection_ids and adds collection_id to env" do
            expect(env.attributes).to have_key(:member_of_collection_ids)
            expect(env.attributes[:member_of_collection_ids].size).to eq 1
            expect(subject.create(env)).to be true
            expect(env.attributes).not_to have_key(:member_of_collection_ids)
            expect(env.attributes).to have_key(:collection_id)
            expect(env.attributes[:collection_id]).to eq collection.id
          end
        end

        context "when more than one collection" do
          let(:collection2) { create(:collection) }
          let(:attributes) do
            { member_of_collection_ids: [collection.id, collection2.id], title: ['test'] }
          end

          it "removes member_of_collection_ids and does NOT add collection_id" do
            expect(env.attributes).to have_key(:member_of_collection_ids)
            expect(env.attributes[:member_of_collection_ids].size).to eq 2
            expect(subject.create(env)).to be true
            expect(env.attributes).not_to have_key(:member_of_collection_ids)
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
