# frozen_string_literal: true
RSpec.describe Hyrax::Collections::NestedCollectionQueryService, clean_repo: true do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:repository) { Blacklight::Solr::Repository.new(blacklight_config) }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }
  let(:current_ability) { ability }
  let(:scope) { double('Scope', can?: true, current_ability: current_ability, repository: repository, blacklight_config: blacklight_config, search_state_class: nil) }

  let(:collection_type) { create(:collection_type) }
  let(:another_collection_type) { create(:collection_type) }

  let(:coll_a) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type)
  end
  let(:coll_b) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type,
          member_of_collection_ids: [coll_a.id])
  end
  let(:coll_c) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type,
          member_of_collection_ids: [coll_b.id])
  end
  let(:coll_d) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type,
          member_of_collection_ids: [coll_c.id])
  end
  let(:coll_e) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type,
          member_of_collection_ids: [coll_d.id])
  end
  let(:another) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: collection_type)
  end
  let(:wrong) do
    valkyrie_create(:hyrax_collection, :public,
          collection_type: another_collection_type)
  end

  describe '.available_child_collections' do
    describe 'given parent is not nestable?' do
      subject { described_class.available_child_collections(parent: parent_double, scope: scope) }

      let(:parent_double) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given parent is nestable?' do
      subject { described_class.available_child_collections(parent: coll_c, scope: scope) }

      before do
        coll_e # this will also create coll_a through coll_d
        another
        wrong
      end

      describe 'and cannot deposit to the parent' do
        it 'returns an empty array' do
          expect(scope).to receive(:can?).with(:deposit, coll_c).and_return(false)
          expect(described_class).not_to receive(:query_solr)
          expect(subject).to eq([])
        end
      end

      describe 'and can deposit to the parent' do
        describe 'it prevents circular nesting' do
          it 'returns an array of valid collections of the same collection type' do
            expect(scope).to receive(:can?).with(:deposit, coll_c).and_return(true)
            expect(described_class).to receive(:query_solr).with(collection: coll_c, access: :read, scope: scope, limit_to_id: nil, nest_direction: :as_child).and_call_original
            expect(subject.map(&:id)).to contain_exactly(another.id, coll_e.id)
          end
        end
      end
    end
  end

  describe '.available_parent_collections' do
    describe 'given child is not nestable?' do
      subject { described_class.available_parent_collections(child: child_double, scope: scope) }

      let(:child_double) { double(nestable?: false) }

      it { is_expected.to eq([]) }
    end

    describe 'given child is nestable?' do
      describe 'and cannot read the child' do
        subject { described_class.available_parent_collections(child: coll_c, scope: scope) }

        it 'returns an empty array' do
          expect(scope).to receive(:can?).with(:read, coll_c).and_return(false)
          expect(described_class).not_to receive(:query_solr)
          expect(subject).to eq([])
        end
      end

      describe 'and can read the child' do
        subject { described_class.available_parent_collections(child: coll_c, scope: scope) }

        # using create option here because permission template is required for testing :deposit access
        let(:coll_a) do
          valkyrie_create(:hyrax_collection, :public,
                collection_type: collection_type,
                user: user)
        end
        let(:coll_b) do
          valkyrie_create(:hyrax_collection, :public,
                collection_type: collection_type,
                user: user,
                member_of_collection_ids: [coll_a.id])
        end
        let(:coll_c) do
          valkyrie_create(:hyrax_collection, :public,
                collection_type: collection_type,
                user: user,
                with_permission_template: true,
                member_of_collection_ids: [coll_b.id])
        end
        let(:coll_d) do
          valkyrie_create(:hyrax_collection, :public,
                collection_type: collection_type,
                user: user,
                member_of_collection_ids: [coll_c.id])
        end
        let(:coll_e) do
          valkyrie_create(:hyrax_collection, :public,

                 collection_type: collection_type,
                 user: user,
                 member_of_collection_ids: [coll_d.id])
        end
        let(:another) do
          valkyrie_create(:hyrax_collection, :public,
                 collection_type: collection_type,
                 user: user)
        end
        let(:wrong) do
          valkyrie_create(:hyrax_collection, :public,
                collection_type: another_collection_type,
                user: user)
        end

        before do
          coll_e # this will also create coll_a through coll_d
          another
          wrong
        end

        describe 'it prevents circular nesting' do
          it 'returns an array of collections of the same collection type excluding the given collection' do
            expect(scope).to receive(:can?).with(:read, coll_c).and_return(true)
            expect(described_class).to receive(:query_solr).with(collection: coll_c, access: :deposit, scope: scope, limit_to_id: nil, nest_direction: :as_parent).and_call_original
            expect(subject.map(&:id)).to contain_exactly(another.id, coll_a.id)
          end
        end
      end
    end
  end

  describe '.parent_and_child_can_nest?' do
    let(:parent) { coll_c }
    let(:child) { another }

    subject { described_class.parent_and_child_can_nest?(parent: parent, child: child, scope: scope) }

    before do
      coll_e
      another
      wrong
    end

    describe 'given parent and child are nestable' do
      describe 'and are the same object' do
        let(:child) { parent }

        it { is_expected.to eq(false) }
      end

      describe 'and are of the same collection type' do
        # using create option here because permission template is required for testing :deposit access
        let!(:parent) do
          valkyrie_create(:hyrax_collection, :public,
                 collection_type: collection_type,
                 user: user)
        end
        let!(:child) do
          valkyrie_create(:hyrax_collection, :public,
                 collection_type: collection_type,
                 user: user)
        end

        it { is_expected.to eq(true) }
      end
      describe 'and the ability does not permit the actions' do
        before do
          expect(scope).to receive(:can?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
      describe 'and are of different collection types' do
        before { allow(parent).to receive(:==).and_return(false) }
        let(:parent) { double(nestable?: true, collection_type_gid: 'another', id: 'parent_collection') }

        it { is_expected.to eq(false) }
      end
    end

    describe 'given parent is not nestable?' do
      before { allow(parent).to receive(:==).and_return(false) }
      let(:parent) { double(nestable?: false, collection_type_gid: 'same', id: 'parent_collection') }

      it { is_expected.to eq(false) }
    end
    describe 'given child is not nestable?' do
      before { allow(parent).to receive(:==).and_return(false) }
      let(:child) { double(nestable?: false, collection_type_gid: 'same', id: 'child_collection') }

      it { is_expected.to eq(false) }
    end
    describe 'not in available parent collections' do
      before do
        allow(described_class).to receive(:available_parent_collections).with(child: child, scope: scope, limit_to_id: parent.id).and_return([])
      end

      it { is_expected.to eq(false) }
    end
    describe 'not in available child collections' do
      before do
        allow(described_class).to receive(:available_child_collections).with(parent: parent, scope: scope, limit_to_id: child.id).and_return([])
      end

      it { is_expected.to eq(false) }
    end
  end
end
