RSpec.describe Hyrax::Forms::Dashboard::NestCollectionForm, type: :form do
  let(:parent) { double(nestable?: true) }
  let(:child) { double(nestable?: true) }
  let(:query_service) { double('Query Service') }
  let(:persistence_service) { double('Persistence Service', persist_nested_collection: true) }
  let(:form) { described_class.new(parent: parent, child: child, query_service: query_service, persistence_service: persistence_service) }

  subject { form }

  it { is_expected.to validate_presence_of(:parent) }
  it { is_expected.to validate_presence_of(:child) }

  describe '.default_query_service' do
    subject { described_class.default_query_service }

    it { is_expected.to respond_to(:available_parent_collections) }
    it { is_expected.to respond_to(:available_child_collections) }
    it { is_expected.to respond_to(:parent_and_child_can_nest?) }
  end

  describe '#default_query_service' do
    subject { described_class.default_persistence_service }

    it { is_expected.to respond_to(:persist_nested_collection_for) }
  end

  it 'is invalid if child cannot be nested within the parent' do
    expect(query_service).to receive(:parent_and_child_can_nest?).with(parent: parent, child: child).and_return(false)
    subject.valid?
    expect(subject.errors[:parent]).to eq(["cannot have child nested within it"])
    expect(subject.errors[:child]).to eq(["cannot nest within parent"])
  end

  describe 'parent is not nestable' do
    let(:parent) { double(nestable?: false) }

    it 'is not valid' do
      subject.valid?
      expect(subject.errors[:parent]).to eq(["is not nestable"])
    end
  end

  describe 'child is not nestable' do
    let(:child) { double(nestable?: false) }

    it 'is not valid' do
      subject.valid?
      expect(subject.errors[:child]).to eq(["is not nestable"])
    end
  end

  describe '#save' do
    subject { form.save }

    describe 'when not valid' do
      before do
        expect(form).to receive(:valid?).and_return(false)
      end
      it { is_expected.to be_falsey }
      it 'does not even attempt to persist the relationship' do
        expect(persistence_service).not_to receive(:persist_nested_collection_for)
        subject
      end
    end
    describe 'when valid' do
      before do
        expect(form).to receive(:valid?).and_return(true)
      end
      it "returns the result of the given persistence_service's call to persist_nested_collection_for" do
        expect(persistence_service).to receive(:persist_nested_collection_for).with(parent: parent, child: child).and_return(:persisted)
        subject
      end
    end
  end

  describe '#available_child_collections' do
    subject { form.available_child_collections }

    it 'delegates to the underlying query_service' do
      expect(query_service).to receive(:available_child_collections).with(parent: parent).and_return(:results)
      expect(subject).to eq(:results)
    end
  end
  describe '#available_parent_collections' do
    subject { form.available_parent_collections }

    it 'delegates to the underlying query_service' do
      expect(query_service).to receive(:available_parent_collections).with(child: child).and_return(:results)
      expect(subject).to eq(:results)
    end
  end
end
