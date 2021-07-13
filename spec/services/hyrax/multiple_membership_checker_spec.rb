# frozen_string_literal: true
RSpec.describe Hyrax::MultipleMembershipChecker, :clean_repo do
  let(:item) { double }

  describe '#initialize' do
    subject { described_class.new(item: item) }

    it 'exposes an attr_reader' do
      expect(subject.item).to eq item
    end
  end

  describe '#check' do
    let(:checker) { described_class.new(item: item) }
    let(:collection_ids) { ['foobar'] }
    let(:included) { false }
    let!(:collection_type) { create(:collection_type, title: 'Greedy', allow_multiple_membership: false) }
    let(:collection_types) { [collection_type] }
    let(:collection_type_gids) { [collection_type.to_global_id] }
    let(:field_pairs) do
      {
        id: collection_ids,
        collection_type_gid_ssim: collection_type_gids.map(&:to_s)
      }
    end
    let(:field_pairs_for_col2) do
      {
        id: [collection2.id],
        collection_type_gid_ssim: collection_type_gids.map(&:to_s)
      }
    end
    let(:use_valkyrie) { true }

    before do
      allow(Hyrax::CollectionType).to receive(:gids_that_do_not_allow_multiple_membership).and_return(collection_type_gids)
    end

    subject { checker.check(collection_ids: collection_ids, include_current_members: included) }

    context 'when there are no single-membership collection types' do
      it 'returns nil' do
        expect(Hyrax::CollectionType).to receive(:gids_that_do_not_allow_multiple_membership).and_return([])
        expect(subject).to be nil
      end
    end

    context 'when collection_ids is empty' do
      let(:collection_ids) { [] }

      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Hyrax::SolrQueryService).not_to receive(:new)
        expect(subject).to be nil
      end
    end

    context 'when there are no single-membership collection instances' do
      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_return([])
        expect(Hyrax::SolrQueryService).not_to receive(:new)
        expect(subject).to be nil
      end
    end

    context 'when multiple single-membership collection instances are not in the list' do
      let(:collection) { create(:collection_lw, id: 'collection0', collection_type: collection_type, with_solr_document: true) }
      let(:collections) { [collection] }
      let(:collection_ids) { collections.map(&:id) }

      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst = double)
        expect(inst).to receive(:with_model).with(model: ::Collection).once.and_return(inst_with_model = double)
        expect(inst_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').once.and_return(inst_with_full_query = double)
        expect(inst_with_full_query).to receive(:get_objects).with(use_valkyrie: true).once.and_return(collections)
        expect(subject).to be nil
      end
    end

    context 'when multiple single-membership collection instances are in the list, not including current members' do
      let(:collection1) { create(:collection_lw, id: 'collection1', title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
      let(:collection2) { create(:collection_lw, id: 'collection2', title: ['Bar'], collection_type: collection_type, with_solr_document: true) }
      let(:collections) { [collection1, collection2] }
      let(:collection_ids) { collections.map(&:id) }

      it 'returns an error' do
        expect(item).not_to receive(:member_of_collection_ids)
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst = double)
        expect(inst).to receive(:with_model).with(model: ::Collection).once.and_return(inst_with_model = double)
        expect(inst_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').once.and_return(inst_with_full_query = double)
        expect(inst_with_full_query).to receive(:get_objects).with(use_valkyrie: true).once.and_return(collections)
        expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection type (type: Greedy, collections: Foo and Bar)'
      end

      context 'with multiple single membership collection types' do
        let!(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection_type_gids) { [collection_type.to_global_id, collection_type_2.to_global_id] }

        it 'returns an error' do
          expect(item).not_to receive(:member_of_collection_ids)
          expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
          expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst = double)
          expect(inst).to receive(:with_model).with(model: ::Collection).once.and_return(inst_with_model = double)
          expect(inst_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').once.and_return(inst_with_full_query = double)
          expect(inst_with_full_query).to receive(:get_objects).with(use_valkyrie: true).once.and_return(collections)
          expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection type (type: Greedy, collections: Foo and Bar)'
        end
      end
    end

    context 'when multiple single-membership collection instances are in the list, including current members' do
      let(:collection1) { create(:collection_lw, id: 'collection1', title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
      let(:collection2) { create(:collection_lw, id: 'collection2', title: ['Bar'], collection_type: collection_type, with_solr_document: true) }
      let(:collections) { [collection1] }
      let(:collection_ids) { collections.map(&:id) }
      let(:included) { true }

      before do
        allow(item).to receive(:member_of_collection_ids).once.and_return([collection2.id])
      end

      it 'returns an error' do
        expect(item).to receive(:member_of_collection_ids)
        expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst1 = double, inst2 = double)
        expect(inst1).to receive(:with_model).with(model: ::Collection).and_return(inst1_with_model = double)
        expect(inst1_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').and_return(inst1_with_full_query = double)
        expect(inst1_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return(collections)
        expect(inst2).to receive(:with_model).with(model: ::Collection).and_return(inst2_with_model = double)
        expect(inst2_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs_for_col2, join_with: ' OR ').and_return(inst2_with_full_query = double)
        expect(inst2_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return([collection2])
        expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection type (type: Greedy, collections: Foo and Bar)'
      end

      context 'with multiple single membership collection types' do
        let!(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
        let(:collection_type_gids) { [collection_type.to_global_id, collection_type_2.to_global_id] }

        it 'returns an error' do
          expect(item).to receive(:member_of_collection_ids)
          expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst1 = double, inst2 = double)
          expect(inst1).to receive(:with_model).with(model: ::Collection).and_return(inst1_with_model = double)
          expect(inst1_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').and_return(inst1_with_full_query = double)
          expect(inst1_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return(collections)
          expect(inst2).to receive(:with_model).with(model: ::Collection).and_return(inst2_with_model = double)
          expect(inst2_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs_for_col2, join_with: ' OR ').and_return(inst2_with_full_query = double)
          expect(inst2_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return([collection2])
          expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection type (type: Greedy, collections: Foo and Bar)'
        end
      end
    end

    context 'when multiple single-membership collection instances are in the list, but are different collection types' do
      let(:collection1) { create(:collection_lw, title: ['Foo'], collection_type: collection_type, with_solr_document: true) }
      let(:collection2) { create(:collection_lw, title: ['Bar'], collection_type: collection_type_2, with_solr_document: true) }
      let(:collections) { [collection1, collection2] }
      let(:collection_ids) { collections.map(&:id) }
      let(:collection_type_2) { create(:collection_type, title: 'Doc', allow_multiple_membership: false) }
      let(:collection_type_gids) { [collection_type.to_global_id, collection_type_2.to_global_id] }

      it 'returns nil' do
        expect(item).not_to receive(:member_of_collection_ids)
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst = double)
        expect(inst).to receive(:with_model).with(model: ::Collection).once.and_return(inst_with_model = double)
        expect(inst_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').once.and_return(inst_with_full_query = double)
        expect(inst_with_full_query).to receive(:get_objects).with(use_valkyrie: true).once.and_return(collections)
        expect(subject).to be nil
      end

      context 'when including current members' do
        let(:collections) { [collection1] }
        let(:included) { true }

        before do
          allow(item).to receive(:member_of_collection_ids).once.and_return([collection2.id])
        end

        it 'returns nil' do
          expect(item).to receive(:member_of_collection_ids)
          expect(Hyrax::SolrQueryService).to receive(:new).and_return(inst1 = double, inst2 = double)
          expect(inst1).to receive(:with_model).with(model: ::Collection).and_return(inst1_with_model = double)
          expect(inst1_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs, join_with: ' OR ').and_return(inst1_with_full_query = double)
          expect(inst1_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return(collections)
          expect(inst2).to receive(:with_model).with(model: ::Collection).and_return(inst2_with_model = double)
          expect(inst2_with_model).to receive(:with_field_pairs).with(field_pairs: field_pairs_for_col2, join_with: ' OR ').and_return(inst2_with_full_query = double)
          expect(inst2_with_full_query).to receive(:get_objects).with(use_valkyrie: true).and_return([collection2])
          expect(subject).to be nil
        end
      end
    end
  end
end
