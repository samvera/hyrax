# frozen_string_literal: true
RSpec.describe Hyrax::MultipleMembershipChecker, :clean_repo do
  let(:item) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }
  let(:user) { FactoryBot.create(:user) }

  describe '#initialize' do
    it 'exposes an attr_reader' do
      expect(described_class.new(item: item)).to have_attributes(item: item)
    end
  end

  describe '#check' do
    let(:base_errmsg) { "Error: You have specified more than one of the same single-membership collection type" }

    let(:checker) { described_class.new(item: item) }
    let(:collection_ids) { ['foobar'] }
    let(:included) { false }
    let!(:collection_type) { FactoryBot.create(:collection_type, title: 'Greedy', allow_multiple_membership: false) }
    let(:collection_types) { [collection_type] }
    let(:collection_type_gids) { [collection_type.to_global_id] }

    before do
      allow(Hyrax::CollectionType).to receive(:gids_that_do_not_allow_multiple_membership)
        .and_return(collection_type_gids)
    end

    subject { checker.check(collection_ids: collection_ids, include_current_members: included) }

    context 'when there are no single-membership collection types' do
      it 'returns nil' do
        expect(Hyrax::CollectionType).to receive(:gids_that_do_not_allow_multiple_membership)
          .and_return([])
        expect(subject).to be nil
      end
    end

    context 'when collection_ids is empty' do
      let(:collection_ids) { [] }

      it 'returns nil' do
        expect(checker).to receive(:filter_to_single_membership_collections)
          .with(collection_ids).once.and_call_original
        expect(Hyrax::SolrQueryService).not_to receive(:new)
        expect(subject).to be nil
      end
    end

    context 'when there are no single-membership collection instances' do
      it 'returns nil' do
        expect(checker).to receive(:filter_to_single_membership_collections)
          .with(collection_ids).once.and_return([])
        expect(Hyrax::SolrQueryService).not_to receive(:new)
        expect(subject).to be nil
      end
    end

    context 'when called from actor stack' do
      # actor stack passes in all parent collections, existing and new; do not
      # want to include item's existing collections or they will be in the checked
      # list twice causing the check to always fail if the item is already in a
      # single membership collection
      let(:included) { false }

      context 'and multiple single-membership collections of the same type exist' do
        let(:collection1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        before do
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: item, user: user)
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: collection1, user: user)
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: collection2, user: user)
        end

        context 'and only one is in the list' do
          let(:collections) { [collection1] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns nil' do
            expect(subject).to be nil
          end
        end

        context 'and both are in the list' do
          let(:collections) { [collection1, collection2] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns an error' do
            regexp = /#{base_errmsg} \(type: Greedy, collections: (Foo and Bar|Bar and Foo)\)/
            expect(subject).to match regexp
          end
        end
      end

      context 'and multiple single-membership collection instances of different types exist' do
        let!(:collection_type_2) { FactoryBot.create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection3) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Baz'],
                                     collection_type_gid: collection_type_2.to_global_id.to_s)
        end

        before do
          Hyrax.publisher.publish('object.metadata.updated', object: collection1, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection2, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection3, user: user)
        end

        context 'and collections of both types are passed in' do
          let(:collections) { [collection1, collection3] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns nil' do
            expect(subject).to be nil
          end
        end

        context 'and collections of the same type are passed in' do
          let(:collections) { [collection1, collection2] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns an error' do
            regexp = /#{base_errmsg} \(type: Greedy, collections: (Foo and Bar|Bar and Foo)\)/
            expect(subject).to match regexp
          end
        end
      end
    end

    context 'when incrementally adding collections' do
      # for incremental add, the proposed collection list only includes the new collections, so need to include the existing collections
      # in the checked list to catch the case where the item is already in a single membership collection of the same collection type
      let(:included) { true }

      context 'and multiple single-membership collections of the same type exist' do
        let(:collection1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end
        let(:item_2) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }

        context 'and only one is in the list' do
          let(:collections) { [collection1] }
          let(:collection_ids) { collections.map(&:id) }

          context 'and the member is already in the other single membership collection' do
            before do
              [item, item_2].each do |work|
                work.member_of_collection_ids += [collection2.id]
                Hyrax.persister.save(resource: work)
                Hyrax.publisher.publish('object.metadata.updated', object: work, user: user)
              end
              Hyrax.publisher.publish('object.metadata.updated', object: collection1, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection2, user: user)
            end

            it 'returns an error' do
              regexp = /#{base_errmsg} \(type: Greedy, collections: (Foo and Bar|Bar and Foo)\)/
              expect(subject).to match regexp
            end
          end

          context 'and the member is not already in the other single membership collection' do
            before do
              item_2.member_of_collection_ids += [collection2.id]
              Hyrax.persister.save(resource: item_2)
              Hyrax.publisher.publish('object.metadata.updated', object: item_2, user: user)

              Hyrax.publisher.publish('object.metadata.updated', object: item, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection1, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection2, user: user)
            end

            it 'returns nil' do
              expect(subject).to be nil
            end
          end
        end
      end

      context 'and multiple single-membership collection instances of different types exist' do
        let!(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: collection_type.to_global_id.to_s)
        end

        let(:collection3) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Baz'],
                                     collection_type_gid: collection_type_2.to_global_id.to_s)
        end

        before do
          Hyrax.publisher.publish('object.metadata.updated', object: collection1, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection2, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection3, user: user)
        end

        context 'and collections of both types are passed in' do
          let(:collections) { [collection1, collection3] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns nil' do
            expect(subject).to be nil
          end
        end

        context 'and collections of the same type are passed in' do
          let(:collections) { [collection1, collection2] }
          let(:collection_ids) { collections.map(&:id) }

          it 'returns an error' do
            regexp = /#{base_errmsg} \(type: Greedy, collections: (Foo and Bar|Bar and Foo)\)/
            expect(subject).to match regexp
          end
        end
      end
    end
  end

  describe '#validate' do
    let(:base_errmsg) { "Error: You have specified more than one of the same single-membership collection type" }

    let(:checker) { described_class.new(item: item) }
    let(:collection_ids) { ['foobar'] }
    let!(:collection_type) { FactoryBot.create(:collection_type, title: 'Greedy', allow_multiple_membership: false) }
    let(:collection_types) { [collection_type] }
    let(:collection_type_gids) { [collection_type.to_global_id] }

    context 'when the item has 0 collections' do
      let(:item) { FactoryBot.build(:hyrax_work) }

      it 'returns true' do
        expect(checker.validate).to be true
      end
    end

    context 'when the item has 1 collection' do
      let(:item) { FactoryBot.build(:hyrax_work, :as_collection_member) }

      it 'returns true' do
        expect(checker.validate).to be true
      end
    end

    context 'when there are no single-membership collection types' do
      before { allow(Hyrax::CollectionType).to receive(:gids_that_do_not_allow_multiple_membership).and_return([]) }

      it 'returns true' do
        expect(checker.validate).to be true
      end
    end

    context 'when there are no single-membership collection instances' do
      let(:item) { FactoryBot.build(:hyrax_work, :as_member_of_multiple_collections) }
      let(:collection_ids) { item.member_of_collection_ids }
      it 'returns true' do
        expect(checker.validate).to be true
      end
    end

    context 'when there are single-membership collection instances' do
      let!(:sm_collection_type1) { FactoryBot.create(:collection_type, title: 'Single Membership 1', allow_multiple_membership: false) }
      let!(:sm_collection_type2) { FactoryBot.create(:collection_type, title: 'Single Membership 2', allow_multiple_membership: false) }

      context 'and the collections are of different single-membership types' do
        let(:item) { FactoryBot.build(:hyrax_work, member_of_collection_ids: collection_ids) }
        let(:col1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: sm_collection_type1.to_global_id,
                                     with_index: true)
        end
        let(:col2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: sm_collection_type2.to_global_id,
                                     with_index: true)
        end
        let(:collection_ids) { [col1.id, col2.id] }

        it 'returns true' do
          expect(checker.validate).to be true
        end
      end

      context 'and the collections are of same single-membership types' do
        let(:item) { FactoryBot.build(:hyrax_work, member_of_collection_ids: collection_ids) }
        let(:col1) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Foo'],
                                     collection_type_gid: sm_collection_type1.to_global_id,
                                     with_index: true)
        end
        let(:col2) do
          FactoryBot.valkyrie_create(:hyrax_collection,
                                     title: ['Bar'],
                                     collection_type_gid: sm_collection_type1.to_global_id,
                                     with_index: true)
        end
        let(:collection_ids) { [col1.id, col2.id] }

        it 'returns an error' do
          regexp = /#{base_errmsg} \(type: Single Membership 1, collections: (Foo and Bar|Bar and Foo)\)/
          expect(checker.validate).to match regexp
        end
      end

      context 'and some collections are of same single-membership types' do
        let(:item) { FactoryBot.build(:hyrax_work, member_of_collection_ids: collection_ids) }
        let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Foo'], collection_type_gid: sm_collection_type1.to_global_id) }
        let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Bar'], collection_type_gid: sm_collection_type1.to_global_id) }
        let(:col3) { FactoryBot.valkyrie_create(:hyrax_collection, title: ['Baz']) }
        let(:collection_ids) { [col1.id, col2.id, col3.id] }

        it 'returns an error' do
          regexp = /#{base_errmsg} \(type: Single Membership 1, collections: (Foo and Bar|Bar and Foo)\)/
          expect(checker.validate).to match regexp
        end
      end
    end
  end
end
