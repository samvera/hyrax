# frozen_string_literal: true
RSpec.describe Hyrax::Forms::Dashboard::NestCollectionForm, type: :form do
  let(:context) { double('Context', current_user: user) }
  let(:user)    { create(:user) }

  let(:persistence_service) do
    double(Hyrax::Collections::NestedCollectionPersistenceService,
           persist_nested_collection: true)
  end

  let(:query_service) do
    double(Hyrax::Collections::NestedCollectionQueryService)
  end

  describe '.default_query_service' do
    subject { described_class.default_query_service }

    it { is_expected.to respond_to(:available_parent_collections) }
    it { is_expected.to respond_to(:available_child_collections) }
    it { is_expected.to respond_to(:parent_and_child_can_nest?) }
  end

  describe '.default_persistence_service' do
    subject { described_class.default_persistence_service }

    it { is_expected.to respond_to(:persist_nested_collection_for) }
  end

  context "when parent/child are ActiveFedora object", :active_fedora do
    subject(:form) do
      described_class.new(parent: parent,
                          child: child,
                          context: context,
                          query_service: query_service,
                          persistence_service: persistence_service)
    end

    let(:child)                { FactoryBot.create(:collection) }
    let(:parent)               { FactoryBot.create(:collection) }

    it { is_expected.to validate_presence_of(:parent) }
    it { is_expected.to validate_presence_of(:child) }

    context 'parent and child nesting' do
      it 'is invalid if child cannot be nested within the parent' do
        expect(query_service).to receive(:parent_and_child_can_nest?).with(parent: parent, child: child, scope: context).and_return(false)

        expect { form.valid? }
          .to change { form.errors.to_hash }
          .to include parent: ["cannot have child nested within it"],
                      child: ["cannot nest within parent"]
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
            .with(parent: parent, child: child, user: user)
            .and_return(:persisted)

          expect(form.save).to eq :persisted
        end
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
        let(:parent) { double(nestable?: true) }

        it 'validates the parent can contain nested subcollections' do
          expect(form.validate_add).to eq true
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
          expect(persistence_service)
            .to receive(:remove_nested_relationship_for)
            .with(parent: parent, child: child, user: user)
            .and_return(:persisted)

          expect(form.remove).to eq :persisted
        end
      end
    end
  end

  context "when receiving parent/child Valkyrie IDs" do
    subject(:form) do
      described_class.new(parent_id: parent_id,
                          child_id: child_id,
                          context: context,
                          query_service: query_service,
                          persistence_service: persistence_service)
    end

    let(:child_nestable) { true }
    let(:child_collection_type_gid) do
      FactoryBot.create(:collection_type, nestable: child_nestable).to_global_id
    end
    let(:child) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 collection_type_gid: child_collection_type_gid)
    end
    let(:child_id) { child.id }

    let(:parent_nestable) { true }
    let(:parent_collection_type_gid) do
      FactoryBot.create(:collection_type, nestable: parent_nestable).to_global_id
    end
    let(:parent) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 collection_type_gid: parent_collection_type_gid)
    end
    let(:parent_id) { parent.id }

    it { is_expected.to validate_presence_of(:parent) }
    it { is_expected.to validate_presence_of(:child) }

    context 'parent and child nesting' do
      it 'is invalid if child cannot be nested within the parent' do
        expect(query_service).to receive(:parent_and_child_can_nest?).with(parent: parent, child: child, scope: context).and_return(false)

        expect { form.valid? }
          .to change { form.errors.to_hash }
          .to include parent: ["cannot have child nested within it"],
                      child: ["cannot nest within parent"]
      end
    end

    describe 'parent is not nestable' do
      let(:parent_nestable) { false }

      it 'is not valid' do
        expect { form.valid? }
          .to change { form.errors.to_hash }
          .to include parent: ["is not nestable"]
      end
    end

    describe 'child is not nestable' do
      let(:child_nestable) { false }

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
            .with(parent: parent, child: child, user: user)
            .and_return(:persisted)

          expect(form.save).to eq :persisted
        end
      end
    end

    describe '#validate_add' do
      context 'when not nestable' do
        let(:parent_nestable) { false }

        it 'validates the parent cannnot contain nested subcollections' do
          expect { form.validate_add }
            .to change { form.errors.to_hash }
            .to include parent: ["cannot have child nested within it"]
        end
      end

      context 'when nestable' do
        let(:parent_nestable) { true }

        it 'validates the parent can contain nested subcollections' do
          expect(form.validate_add).to eq true
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
          expect(persistence_service)
            .to receive(:remove_nested_relationship_for)
            .with(parent: parent, child: child, user: user)
            .and_return(:persisted)

          expect(form.remove).to eq :persisted
        end
      end
    end
  end
end
