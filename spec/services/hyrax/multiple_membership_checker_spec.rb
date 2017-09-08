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

    subject { checker.check(collection_ids: collection_ids, include_current_members: included) }

    context 'when there are no single-membership collection types' do
      before do
        allow(Hyrax::CollectionType).to receive(:where).and_return([])
      end

      it 'returns nil' do
        expect(checker).to receive(:single_membership_types).and_return([]).and_call_original
        expect(subject).to be nil
      end
    end

    context 'when collection_ids is empty' do
      let(:collection_ids) { [] }

      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Collection).not_to receive(:where)
        expect(subject).to be nil
      end
    end

    context 'when there are no single-membership collection instances' do
      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Collection).to receive(:where).once.and_return([])
        expect(subject).to be nil
      end
    end

    context 'when multiple single-membership collection instances are not in the list' do
      let(:collection) { create(:collection) }
      let(:collections) { [collection] }
      let(:collection_ids) { collections.map(&:id) }

      before do
        allow(collection).to receive(:collection_type_gid).and_return(collection_type.gid)
      end

      it 'returns nil' do
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Collection).to receive(:where).once.and_return(collections)
        expect(subject).to be nil
      end
    end

    context 'when multiple single-membership collection instances are in the list, not including current members' do
      let(:collection1) { create(:collection, title: ['Foo']) }
      let(:collection2) { create(:collection, title: ['Bar']) }
      let(:collections) { [collection1, collection2] }
      let(:collection_ids) { collections.map(&:id) }

      before do
        allow(collection1).to receive(:collection_type_gid).and_return(collection_type.gid)
        allow(collection2).to receive(:collection_type_gid).and_return(collection_type.gid)
      end

      it 'returns nil' do
        expect(item).not_to receive(:member_of_collection_ids)
        expect(checker).to receive(:single_membership_collections).with(collection_ids).once.and_call_original
        expect(Collection).to receive(:where).once.and_return(collections)
        expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection types: Greedy (Foo and Bar)'
      end
    end

    context 'when multiple single-membership collection instances are in the list, including current members' do
      let(:collection1) { create(:collection, title: ['Foo']) }
      let(:collection2) { create(:collection, title: ['Bar']) }
      let(:collections) { [collection1] }
      let(:collection_ids) { collections.map(&:id) }
      let(:included) { true }

      before do
        allow(collection1).to receive(:collection_type_gid).and_return(collection_type.gid)
        allow(collection2).to receive(:collection_type_gid).and_return(collection_type.gid)
        allow(item).to receive(:member_of_collection_ids).once.and_return([collection2.id])
      end

      it 'returns nil' do
        expect(item).to receive(:member_of_collection_ids)
        expect(Collection).to receive(:where).with(id: collection_ids, collection_type_gid_ssim: collection_type.gid).once.and_return(collections)
        expect(Collection).to receive(:where).with(id: [collection2.id], collection_type_gid_ssim: collection_type.gid).once.and_return([collection2])
        expect(subject).to eq 'Error: You have specified more than one of the same single-membership collection types: Greedy (Foo and Bar)'
      end
    end
  end
end
