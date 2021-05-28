# frozen_string_literal: true
RSpec.describe Hyrax::Forms::Dashboard::NestCollectionForm, type: :form do
  subject(:form) do
    described_class.new(parent: parent,
                        child: child,
                        context: context,
                        query_service: query_service,
                        persistence_service: persistence_service)
  end

  let(:child)                { FactoryBot.create(:collection) }
  let(:context)              { double('Context') }
  let(:nesting_depth_result) { true }
  let(:parent)               { FactoryBot.create(:collection) }

  let(:persistence_service) do
    double(Hyrax::Collections::NestedCollectionPersistenceService,
           persist_nested_collection: true)
  end

  let(:query_service) do
    double(Hyrax::Collections::NestedCollectionQueryService,
           valid_combined_nesting_depth?: nesting_depth_result)
  end

  it { is_expected.to validate_presence_of(:parent) }
  it { is_expected.to validate_presence_of(:child) }

  describe '.default_query_service' do
    subject { described_class.default_query_service }

    it { is_expected.to respond_to(:available_parent_collections) }
    it { is_expected.to respond_to(:available_child_collections) }
    it { is_expected.to respond_to(:parent_and_child_can_nest?) }
    it { is_expected.to respond_to(:valid_combined_nesting_depth?) }
  end

  describe '.default_persistence_service' do
    subject { described_class.default_persistence_service }

    it { is_expected.to respond_to(:persist_nested_collection_for) }
  end

  context 'parent and child nesting' do
    let(:nesting_depth_result) { false }

    it 'is invalid if child cannot be nested within the parent' do
      expect(query_service).to receive(:parent_and_child_can_nest?).with(parent: parent, child: child, scope: context).and_return(false)

      expect { form.valid? }
        .to change { form.errors.to_hash }
        .to include parent: ["cannot have child nested within it"],
                    child: ["cannot nest within parent"],
                    collection: ["nesting exceeds the allowed maximum nesting depth."]
    end
  end

  describe 'parent is not nestable' do
    let(:parent) { double(nestable?: false) }

    it 'is not valid' do
      expect { form.valid? }
        .to change { form.errors.to_hash }
        .to include parent: ["is not nestable"]
    end
  end

  describe 'child is not nestable' do
    let(:child) { double(nestable?: false) }

    it 'is not valid' do
      expect { form.valid? }
        .to change { form.errors.to_hash }
        .to include child: ["is not nestable"]
    end
  end

  describe '#save' do
    describe 'when not valid' do
      it 'does not even attempt to persist the relationship' do
        expect(form).to receive(:valid?).and_return(false) # rubocop:disable RSpec/SubjectStub
        expect(persistence_service).not_to receive(:persist_nested_collection_for)

        expect(form.save).to be_falsey
      end
    end

    describe 'when valid' do
      before { expect(form).to receive(:valid?).and_return(true) } # rubocop:disable RSpec/SubjectStub

      it "returns the result of the given persistence_service's call to persist_nested_collection_for" do
        expect(persistence_service)
          .to receive(:persist_nested_collection_for)
          .with(parent: parent, child: child)
          .and_return(:persisted)

        expect(form.save).to eq :persisted
      end
    end
  end

  describe '#available_child_collections' do
    it 'delegates to the underlying query_service' do
      expect(query_service)
        .to receive(:available_child_collections)
        .with(parent: parent, scope: context)
        .and_return(:results)

      expect(form.available_child_collections).to eq(:results)
    end
  end

  describe '#available_parent_collections' do
    it 'delegates to the underlying query_service' do
      expect(query_service)
        .to receive(:available_parent_collections)
        .with(child: child, scope: context)
        .and_return(:results)

      expect(form.available_parent_collections).to eq(:results)
    end
  end

  describe '#validate_add' do
    context 'when not nestable' do
      let(:parent) { double(nestable?: false) }

      it 'validates the parent cannnot contain nested subcollections' do
        expect { form.validate_add }
          .to change { form.errors.to_hash }
          .to include parent: ["cannot have child nested within it"]
      end
    end

    context 'when nestable' do
      context 'when at maximum nesting level' do
        let(:parent) { double(nestable?: true) }
        let(:nesting_depth_result) { false }

        it 'validates the parent cannot have additional files nested' do
          expect { form.validate_add }
            .to change { form.errors.to_hash }
            .to include collection: ["nesting exceeds the allowed maximum nesting depth."]
        end
      end

      context 'when valid' do
        let(:parent) { double(nestable?: true) }

        it 'validates the parent can contain nested subcollections' do
          expect(form.validate_add).to eq true
        end
      end
    end
  end

  describe '#remove' do
    describe 'when not authorized' do
      before do
        expect(context).to receive(:can?).with(:edit, parent).and_return(false)
      end

      it 'does not even attempt to persist the relationship' do
        expect(persistence_service).not_to receive(:remove_nested_relationship_for)
        form.remove
        expect(form.errors[:parent]).to eq(["permission is inadequate for removal of nesting relationship"])
      end
    end

    describe 'when authorized' do
      before do
        expect(context).to receive(:can?).with(:edit, parent).and_return(true)
      end

      it "returns the result of the given persistence_service's call to remove_nested_relationship_for" do
        expect(persistence_service).to receive(:remove_nested_relationship_for).with(parent: parent, child: child).and_return(:persisted)

        expect(form.remove).to eq :persisted
      end
    end
  end
end
