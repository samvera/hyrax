# frozen_string_literal: true
RSpec.describe Hyrax::CollectionType, type: :model do
  subject(:collection_type) { FactoryBot.build(:collection_type) }

  shared_context 'with a collection' do
    let(:collection_type) { FactoryBot.create(:collection_type) }
    let!(:collection) { FactoryBot.valkyrie_create(:hyrax_collection, collection_type_gid: collection_type.to_global_id.to_s) }
  end

  describe "validations", :clean_repo do
    let(:collection_type) { FactoryBot.create(:collection_type) }

    it "ensures the required fields have values" do
      collection_type.title = nil
      collection_type.machine_id = nil
      expect(collection_type).not_to be_valid
      expect(collection_type.errors.messages[:title]).not_to be_empty
      expect(collection_type.errors.messages[:machine_id]).not_to be_empty
    end
    it "ensures uniqueness" do
      is_expected.to validate_uniqueness_of(:title)
      is_expected.to validate_uniqueness_of(:machine_id)
    end
  end

  it 'has a description' do
    expect(collection_type.description).not_to be_empty
  end

  it 'has a machine_id' do
    expect(collection_type.machine_id).not_to be_empty
  end

  it 'has a title' do
    expect(collection_type.title).not_to be_empty
  end

  it "has configuration properties with defaults" do
    expect(collection_type).to be_nestable
    expect(collection_type).to be_brandable
    expect(collection_type).to be_discoverable
    expect(collection_type).to be_sharable
    expect(collection_type).to be_share_applies_to_new_works
    expect(collection_type).to allow_multiple_membership
    expect(collection_type).not_to require_membership
    expect(collection_type).not_to assign_workflow
    expect(collection_type).not_to assign_visibility
  end

  context 'class methods' do
    describe '.settings_attributes' do
      it 'lists collection settings methods' do
        expect(described_class.settings_attributes)
          .to include(:nestable?, :discoverable?, :brandable?)
      end
    end

    describe ".any_nestable?" do
      context "when there is a nestable collection type" do
        let!(:collection_type) { FactoryBot.create(:collection_type, nestable: true) }

        it 'returns true' do
          expect(described_class.any_nestable?).to be true
        end
      end

      context "when there are no nestable collection types" do
        let!(:collection_type) { FactoryBot.create(:collection_type, nestable: false) }

        it 'returns false' do
          expect(described_class.any_nestable?).to be false
        end
      end
    end

    describe ".find_or_create_default_collection_type" do
      subject { described_class.find_or_create_default_collection_type }

      it 'creates a default collection type' do
        expect(Hyrax::CollectionTypes::CreateService).to receive(:create_collection_type)
        subject
      end
    end

    describe ".gids_that_do_not_allow_multiple_membership" do
      let!(:type_allows_multiple_membership) { FactoryBot.create(:collection_type, allow_multiple_membership: true) }
      let!(:type_disallows_multiple_membership) { FactoryBot.create(:collection_type, allow_multiple_membership: false) }

      it 'lists the single membership gids' do
        expect(described_class.gids_that_do_not_allow_multiple_membership)
          .to match_array(type_disallows_multiple_membership.to_global_id.to_s)
      end
    end

    describe ".find_or_create_admin_set_type" do
      subject { described_class.find_or_create_admin_set_type }

      it 'creates admin set collection type' do
        machine_id = described_class::ADMIN_SET_MACHINE_ID
        title = described_class::ADMIN_SET_DEFAULT_TITLE
        expect(Hyrax::CollectionTypes::CreateService).to receive(:create_collection_type).with(machine_id: machine_id, title: title, options: anything)
        subject
      end
    end

    describe '.for' do
      include_context 'with a collection'

      it 'returns the collection type for the collection' do
        expect(described_class.for(collection: collection)).to eq collection_type
      end
    end

    describe '.find_by_gid' do
      let(:collection_type) { FactoryBot.create(:collection_type) }

      it 'returns the same collection type with `#to_global_id`' do
        expect(described_class.find_by_gid(collection_type.to_global_id)).to eq collection_type
      end

      it 'returns false if collection type with gid does NOT exist' do
        expect(described_class.find_by_gid('gid://internal/hyrax-collectiontype/NO_EXIST')).to eq false
      end

      it 'returns false if gid is nil' do
        expect(described_class.find_by_gid(nil)).to eq false
      end
    end

    describe '.find_by_gid!' do
      let(:collection_type) { FactoryBot.create(:collection_type) }

      it 'returns the same collection type with `#to_global_id`' do
        expect(described_class.find_by_gid!(collection_type.to_global_id)).to eq collection_type
      end

      it 'raises error if collection type with gid does NOT exist' do
        expect { described_class.find_by_gid!('gid://internal/hyrax-collectiontype/NO_EXIST') }
          .to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'raises error if passed nil' do
        expect { described_class.find_by_gid!(nil) }.to raise_error(URI::InvalidURIError)
      end
    end
  end
  context 'instance methods' do
    let(:collection_type) { FactoryBot.create(:collection_type) }

    describe "#collections" do
      it 'returns empty array if gid is nil' do
        valkyrie_create(:hyrax_collection, collection_type_gid: collection_type.to_global_id.to_s)
        expect(Hyrax.query_service.count_all_of_model(model: CollectionResource)).not_to be_zero
        expect(build(:collection_type).collections).to eq []
      end

      context 'when use_valkyrie is true' do
        let!(:pcdm_collection) { valkyrie_create(:hyrax_collection, collection_type_gid: collection_type.to_global_id.to_s) }

        it 'returns pcdm collections of this collection type' do
          expect(collection_type.collections(use_valkyrie: true).to_a).to include pcdm_collection
        end
      end

      context 'when use_valkyrie is false', :active_fedora do
        let!(:collection) { FactoryBot.create(:collection_lw, collection_type_gid: collection_type.to_global_id.to_s) }

        it 'returns collections of this collection type' do
          expect(collection_type.collections(use_valkyrie: false).to_a).to include collection
        end
      end
    end

    describe "#collections#any?", :clean_repo, :active_fedora do
      it 'returns true if there are any collections of this collection type' do
        FactoryBot.create(:collection_lw, collection_type: collection_type)
        expect(collection_type).to have_collections
      end
      it 'returns false if there are not any collections of this collection type' do
        expect(collection_type).not_to have_collections
      end
    end

    describe "#machine_id" do
      let(:collection_type) { described_class.new }

      it 'assigns machine_id on title=' do
        expect(collection_type.machine_id).to be_blank
        collection_type.title = "New Collection Type"
        expect(collection_type.machine_id).not_to be_blank
      end
    end

    describe '#destroy' do
      include_context 'with a collection'

      it "fails if collections exist of this type" do
        expect(collection_type.destroy).to eq false
        expect(collection_type.errors).not_to be_empty
      end
    end

    describe "#save (no settings changes)" do
      include_context 'with a collection'

      it "succeeds no changes to settings are being made" do
        expect(collection_type.save).to be true
        expect(collection_type.errors).to be_empty
      end
    end

    describe '#save' do
      before { collection_type.nestable = !collection_type.nestable }

      context 'for non-special collection type' do
        include_context 'with a collection'

        it "fails if collections exist of this type and settings are changed" do
          expect(collection_type.save).to be false
          expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for a type that has collections"
        end
      end

      context 'for admin set collection type' do
        let(:collection_type) { FactoryBot.create(:admin_set_collection_type) }

        it 'fails if settings are changed' do
          expect(collection_type.save).to be false
          expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for the Administrative Set type"
        end
      end

      context 'for user collection type' do
        let(:collection_type) { FactoryBot.create(:user_collection_type) }

        it 'fails if settings are changed' do
          expect(collection_type.save).to be false
          expect(collection_type.errors.messages[:base].first).to eq "Collection type settings cannot be altered for the User Collection type"
        end
      end
    end
  end
end
