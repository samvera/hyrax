# frozen_string_literal: true
RSpec.describe Hyrax::Collections::NestedCollectionQueryService, clean_repo: true do
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let(:collection_type_other) { FactoryBot.create(:collection_type) }
  let(:scope) { FakeSearchBuilderScope.new(current_user: user) }
  let(:user) { FactoryBot.create(:user) }

  let(:coll_a) do
    FactoryBot.build(:public_collection,
                     id: 'Collection_A',
                    collection_type: collection_type,
                     with_nesting_attributes:
                       { ancestors: [],
                         parent_ids: [],
                         pathnames: ['Collection_A'],
                         depth: 1 })
  end

  let(:coll_b) do
    FactoryBot.build(:public_collection,
                     id: 'Collection_B',
                     collection_type: collection_type,
                     member_of_collections: [coll_a],
                     with_nesting_attributes:
                       { ancestors: ['Collection_A'],
                         parent_ids: ['Collection_A'],
                         pathnames: ['Collection_A/Collection_B'],
                         depth: 2 })
  end

  let(:coll_c) do
    FactoryBot.build(:public_collection,
                     id: 'Collection_C',
                     collection_type: collection_type,
                     member_of_collections: [coll_b],
                     with_nesting_attributes:
                       { ancestors: ["Collection_A",
                                     "Collection_A/Collection_B"],
                         parent_ids: ['Collection_B'],
                         pathnames: ['Collection_A/Collection_B/Collection_C'],
                         depth: 3 })
  end

  let(:coll_d) do
    FactoryBot.build(:public_collection,
                     id: 'Collection_D',
                     collection_type: collection_type,
                     member_of_collections: [coll_c],
                     with_nesting_attributes:
                       { ancestors: ["Collection_A",
                                     "Collection_A/Collection_B",
                                     "Collection_A/Collection_B/Collection_C"],
                         parent_ids: ['Collection_C'],
                         pathnames: ["Collection_A/Collection_B/Collection_C/Collection_D"],
                         depth: 4 })
  end

  let(:coll_e) do
    FactoryBot.build(:public_collection,
                     id: 'Collection_E',
                     collection_type: collection_type,
                     member_of_collections: [coll_d],
                     with_nesting_attributes:
                       { ancestors: ["Collection_A",
                                     "Collection_A/Collection_B",
                                     "Collection_A/Collection_B/Collection_C",
                                     "Collection_A/Collection_B/Collection_C/Collection_D"],
                         parent_ids: ['Collection_D'],
                         pathnames: ['Collection_A/Collection_B/Collection_C/Collection_D/Collection_E'],
                         depth: 5 })
  end

  let(:another) do
    FactoryBot.build(:public_collection,
                     id: 'Another_One',
                     collection_type: collection_type,
                     with_nesting_attributes:
                       { ancestors: [],
                         parent_ids: [],
                         pathnames: ['Another_One'],
                         depth: 1 })
  end

  let(:wrong) do
    FactoryBot.build(:public_collection,
                     id: 'Wrong_Type',
                     collection_type: collection_type_other,
                     with_nesting_attributes:
                       { ancestors: [],
                         parent_ids: [],
                         pathnames: ['Wrong_Type'],
                         depth: 1 })
  end

  describe '.available_child_collections' do
    context 'when parent is not nestable?' do
      let(:collection) { double(nestable?: false) }

      it 'is empty' do
        expect(described_class.available_child_collections(parent: collection, scope: scope))
          .to be_empty
      end
    end

    context 'when parent is nestable?' do
      before do
        coll_e # this will also build coll_a through coll_d
        another
        wrong
      end

      describe 'and cannot deposit to the parent' do
        before do
          allow(scope)
            .to receive(:can?)
            .with(:deposit, coll_c)
            .and_return(false)
        end

        it 'returns an empty array' do
          expect(described_class.available_child_collections(parent: coll_c, scope: scope))
            .to be_empty
        end

        it 'does not query for subcollections' do
          expect(described_class).not_to receive(:query_solr)
          described_class.available_child_collections(parent: coll_c, scope: scope)
        end
      end

      describe 'and can deposit to the parent' do
        before do
            allow(scope)
              .to receive(:can?)
              .with(:deposit, coll_c)
              .and_return(true)
        end

        describe 'it prevents circular nesting' do
          it 'returns an array of valid collections of the same collection type' do
            expect(described_class.available_child_collections(parent: coll_c, scope: scope))
              .to contain_exactly(have_attributes(id: another.id),
                                  have_attributes(id: coll_e.id))
          end
        end
      end
    end
  end

  describe '.available_parent_collections' do
    describe 'when the proposed member is not nestable?' do
      let(:member) { double(nestable?: false) }

      it 'gives an empty list' do
        expect(described_class.available_parent_collections(child: member, scope: scope))
          .to be_empty
      end
    end

    describe 'given child is nestable?' do
      describe 'and cannot read the child' do
        before do
          allow(scope)
            .to receive(:can?)
            .with(:read, coll_c)
            .and_return(false)
        end

        it 'gives an empty list of available collections' do
          expect(described_class.available_parent_collections(child: coll_c, scope: scope))
            .to be_empty
        end

        it 'does not query solr' do
          expect(described_class).not_to receive(:query_solr)
          described_class.available_parent_collections(child: coll_c, scope: scope)
        end
      end

      describe 'and can read the child', with_nested_reindexing: true do
        let(:coll_a) do
          FactoryBot.build(:public_collection_lw,
                           id: 'Collection_A',
                           collection_type: collection_type,
                           user: user,
                           with_permission_template: true)
        end

        let(:coll_e) do
          FactoryBot.create(:public_collection_lw,
                            id: 'Collection_E',
                            collection_type: collection_type,
                            user: user,
                            with_permission_template: true,
                            member_of_collections: [coll_d])
        end

        let(:another) do
          FactoryBot.create(:public_collection_lw,
                            id: 'Another_One',
                            collection_type: collection_type,
                            user: user,
                            with_permission_template: true)
        end

        before do
          coll_e # this will also build coll_a through coll_d
          another
          wrong
        end

        describe 'it prevents circular nesting' do
          before do
            allow(scope).to receive(:can?).with(:read, coll_c).and_return(true)
          end

          it 'returns an array of collections of the same collection type excluding the given collection' do
            expect(described_class.available_parent_collections(child: coll_c, scope: scope))
              .to contain_exactly(have_attributes(id: coll_a.id),
                                  have_attributes(id: another.id))
          end
        end
      end
    end
  end

  describe '.parent_and_child_can_nest?' do
    before do
      coll_e
      another
      wrong
    end

    describe 'when parent and child are nestable' do
      describe 'and are the same object' do
        it 'is false' do
          expect(described_class.parent_and_child_can_nest?(parent: coll_c, child: coll_c, scope: scope))
            .to eq false
        end
      end

      describe 'and are of the same collection type', with_nested_reindexing: true do
        before { allow(scope).to receive(:can?).and_return(true) }

        let(:collection) do
          FactoryBot.create(:public_collection_lw,
                            id: 'Parent_Collecton',
                            collection_type: collection_type,
                            user: user,
                            with_permission_template: true)
        end

        let(:member) do
          FactoryBot.create(:public_collection_lw,
                            id: 'Child_Collection',
                            collection_type: collection_type,
                            user: user,
                            with_permission_template: true)
        end


        it 'is true' do
          expect(described_class.parent_and_child_can_nest?(parent: collection, child: member, scope: scope))
            .to eq true
        end
      end

      describe 'and the ability does not permit the actions' do
        before { allow(scope).to receive(:can?).and_return(false) }

        it 'is false' do
          expect(described_class.parent_and_child_can_nest?(parent: coll_c, child: another, scope: scope))
            .to eq false
        end
      end

      describe 'and are of different collection types' do
        let(:collection) { double(nestable?: true, collection_type_gid: 'another', id: 'parent_collection') }

        it 'is false' do
          expect(described_class.parent_and_child_can_nest?(parent: collection, child: another, scope: scope))
            .to eq false
        end
      end
    end

    describe 'when the proposed parent is not nestable?' do
      let(:collection) { double(nestable?: false, collection_type_gid: 'same', id: 'parent_collection') }

      it 'is false' do
        expect(described_class.parent_and_child_can_nest?(parent: collection, child: another, scope: scope))
          .to eq false
      end
    end

    describe 'when the proposed child is not nestable?' do
      let(:member) { double(nestable?: false, collection_type_gid: 'same', id: 'child_collection') }

      it 'is false' do
        expect(described_class.parent_and_child_can_nest?(parent: coll_c, child: member, scope: scope))
          .to eq false
      end
    end

    describe 'not in available parent collections' do
      before do
        allow(described_class)
          .to receive(:available_parent_collections)
          .with(child: another, scope: scope, limit_to_id: coll_c.id)
          .and_return([])
      end

      it 'is false' do
        expect(described_class.parent_and_child_can_nest?(parent: coll_c, child: another, scope: scope))
          .to eq false
      end
    end

    describe 'not in available child collections' do
      before do
        allow(described_class)
          .to receive(:available_child_collections)
          .with(parent: coll_c, scope: scope, limit_to_id: another.id)
          .and_return([])
      end

      it 'is false' do
        expect(described_class.parent_and_child_can_nest?(parent: coll_c, child: another, scope: scope))
          .to eq false
      end
    end
  end

  describe '.valid_combined_nesting_depth?' do
    context 'when total depth > limit' do
      it 'returns false' do
        expect(described_class.valid_combined_nesting_depth?(parent: coll_e, child: another, scope: scope))
          .to eq false
      end
    end

    context 'when valid combined depth' do
      it 'returns true' do
        expect(described_class.valid_combined_nesting_depth?(parent: coll_c, child: coll_e, scope: scope))
          .to eq true
      end
    end
  end

  describe 'nesting attributes object', with_nested_reindexing: true do
    let(:collection) do
      FactoryBot.create(:collection_lw, collection_type: collection_type, user: user)
    end

    let(:member) do
      FactoryBot.create(:collection_lw, collection_type: collection_type, user: user)
    end

    let(:nesting_attributes) do
      Hyrax::Collections::NestedCollectionQueryService::NestingAttributes
        .new(id: member.id, scope: scope)
    end

    before do
      Hyrax::Collections::NestedCollectionPersistenceService
        .persist_nested_collection_for(parent: collection, child: member)
    end

    it 'will encapsulate the nesting attributes in an object' do
      expect(nesting_attributes)
        .to have_attributes(id: member.id,
                            parents: contain_exactly(collection.id),
                            pathnames: ["#{collection.id}/#{member.id}"],
                            ancestors: contain_exactly(collection.id),
                            depth: 2)
    end
  end
end
