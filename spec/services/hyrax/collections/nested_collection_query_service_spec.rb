RSpec.describe Hyrax::Collections::NestedCollectionQueryService do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }

  # The admin spec short circuits much of the query
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { double('Scope', can?: true, current_ability: current_ability, repository: repository, blacklight_config: blacklight_config) }
  let(:collection_type) { create(:collection_type) }
  let(:another_collection_type) { create(:collection_type) }

  describe '.available_child_collections' do
    subject { described_class.available_child_collections(parent: parent, scope: scope) }

    describe 'given parent is not nestable?' do
      let(:parent) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given parent is nestable?', clean_repo: true do
      let!(:parent) { create(:public_collection, collection_type_gid: collection_type.gid) }
      let!(:another) { create(:public_collection, collection_type_gid: collection_type.gid) }
      let!(:wrong_type) { create(:public_collection, collection_type_gid: another_collection_type.gid) }

      before do
        allow(parent).to receive(:nestable?).and_return(true)
      end

      it 'returns an array of collections of the same collection type excluding the given collection' do
        expect(subject.map(&:id)).to eq([another.id])
      end
    end
  end
  describe '.available_parent_collections' do
    subject { described_class.available_parent_collections(child: child, scope: scope) }

    describe 'given child is not nestable?' do
      let(:child) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given child is nestable?', clean_repo: true do
      let!(:child) { create(:public_collection, collection_type_gid: collection_type.gid) }
      let!(:another) { create(:public_collection, collection_type_gid: collection_type.gid) }
      let!(:wrong_type) { create(:public_collection, collection_type_gid: another_collection_type.gid) }

      before do
        allow(child).to receive(:nestable?).and_return(true)
      end

      it 'returns an array of collections of the same collection type excluding the given collection' do
        expect(subject.map(&:id)).to eq([another.id])
      end
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
