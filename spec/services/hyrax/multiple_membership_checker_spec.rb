# frozen_string_literal: true
RSpec.describe Hyrax::MultipleMembershipChecker, :clean_repo do
  let(:item) { create(:work, id: 'work-1', user: user) }
  let(:user) { create(:user) }

  describe '#initialize' do
    subject { described_class.new(item: item) }

    it 'exposes an attr_reader' do
      expect(subject.item).to eq item
    end
  end

  describe '#check' do
    let(:base_errmsg) { "Error: You have specified more than one of the same single-membership collection type" }

    let(:checker) { described_class.new(item: item) }
    let(:collection_ids) { ['foobar'] }
    let(:included) { false }
    let!(:collection_type) { create(:collection_type, title: 'Greedy', allow_multiple_membership: false) }
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
          create(:collection_lw, id: 'collection1', title: ['Foo'],
                                 collection_type: collection_type,
                                 with_solr_document: true)
        end
        let(:collection2) do
          create(:collection_lw, id: 'collection2', title: ['Bar'],
                                 collection_type: collection_type,
                                 with_solr_document: true)
        end

        before do
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: item.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: collection1.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated',
                                  object: collection2.valkyrie_resource, user: user)
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
        let!(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection1) { create(:collection_lw, title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
        let(:collection2) { create(:collection_lw, title: ['Bar'], collection_type: collection_type, with_solr_document: true) }
        let(:collection3) { create(:collection_lw, title: ['Baz'], collection_type: collection_type_2, with_solr_document: true) }

        before do
          Hyrax.publisher.publish('object.metadata.updated', object: collection1.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection2.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection3.valkyrie_resource, user: user)
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
        let(:collection1) { create(:collection_lw, id: 'collection1', title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
        let(:collection2) { create(:collection_lw, id: 'collection2', title: ['Bar'], collection_type: collection_type, with_solr_document: true) }
        let(:item_2) { create(:work, id: 'work-2', user: user) }

        context 'and only one is in the list' do
          let(:collections) { [collection1] }
          let(:collection_ids) { collections.map(&:id) }

          context 'and the member is already in the other single membership collection' do
            before do
              [item, item_2].each do |work|
                work.member_of_collections << collection2
                work.save!
                Hyrax.publisher.publish('object.metadata.updated', object: work.valkyrie_resource, user: user)
              end
              Hyrax.publisher.publish('object.metadata.updated', object: collection1.valkyrie_resource, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection2.valkyrie_resource, user: user)
            end

            it 'returns an error' do
              regexp = /#{base_errmsg} \(type: Greedy, collections: (Foo and Bar|Bar and Foo)\)/
              expect(subject).to match regexp
            end
          end

          context 'and the member is not already in the other single membership collection' do
            before do
              [item_2].each do |work|
                work.member_of_collections << collection2
                work.save!
                Hyrax.publisher.publish('object.metadata.updated', object: work.valkyrie_resource, user: user)
              end
              Hyrax.publisher.publish('object.metadata.updated', object: item.valkyrie_resource, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection1.valkyrie_resource, user: user)
              Hyrax.publisher.publish('object.metadata.updated', object: collection2.valkyrie_resource, user: user)
            end

            it 'returns nil' do
              expect(subject).to be nil
            end
          end
        end
      end

      context 'and multiple single-membership collection instances of different types exist' do
        let!(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection1) { create(:collection_lw, title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
        let(:collection2) { create(:collection_lw, title: ['Bar'], collection_type: collection_type, with_solr_document: true) }
        let(:collection3) { create(:collection_lw, title: ['Baz'], collection_type: collection_type_2, with_solr_document: true) }

        before do
          Hyrax.publisher.publish('object.metadata.updated', object: collection1.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection2.valkyrie_resource, user: user)
          Hyrax.publisher.publish('object.metadata.updated', object: collection3.valkyrie_resource, user: user)
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
end
