RSpec.describe Hyrax::Collections::NestedCollectionQueryService do
  let(:ability) { double('Ability', can?: true) }

  describe '.available_child_collections' do
    subject { described_class.available_child_collections(parent: parent, ability: ability) }

    describe 'given parent is not nestable?' do
      let(:parent) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given parent is nestable?' do
      it 'returns an array of collections of the same collection type'
    end
  end
  describe '.available_parent_collections' do
    subject { described_class.available_parent_collections(child: child, ability: ability) }

    describe 'given child is not nestable?' do
      let(:child) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given child is nestable?' do
      it 'returns an array of collections of the same collection type'
    end
  end
  describe '.parent_and_child_can_nest?' do
    let(:child) { double(nestable?: true, collection_type_gid: 'same') }
    let(:parent) { double(nestable?: true, collection_type_gid: 'same') }

    subject { described_class.parent_and_child_can_nest?(parent: parent, child: child) }

    describe 'given parent and child are nestable' do
      describe 'and are the same object' do
        let(:child) { parent }

        it { is_expected.to eq(false) }
      end
      describe 'and are of the same collection type' do
        it { is_expected.to eq(true) }
      end
      describe 'and are of different collection types' do
        let(:parent) { double(nestable?: true, collection_type_gid: 'another') }

        it { is_expected.to eq(false) }
      end
    end

    describe 'given parent is not nestable?' do
      let(:parent) { double(nestable?: false) }

      it { is_expected.to eq(false) }
    end
    describe 'given child is not nestable?' do
      let(:child) { double(nestable?: false) }

      it { is_expected.to eq(false) }
    end
  end
end
