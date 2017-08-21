RSpec.describe Hyrax::Forms::Dashboard::NestCollectionForm, type: :form do
  let(:parent) { double }
  let(:child) { double }
  let(:form) { described_class.new(parent: parent, child: child) }

  subject { form }

  it { is_expected.to validate_presence_of(:parent) }
  it { is_expected.to validate_presence_of(:child) }

  describe '#save' do
    subject { form.save }

    describe 'when not valid' do
      before do
        expect(form).to receive(:valid?).and_return(false)
      end
      it { is_expected.to be_falsey }
      it 'does not even attempt to persist the relationship' do
        expect(subject).not_to receive(:persist!)
        subject
      end
    end
    describe 'when valid' do
      before do
        expect(form).to receive(:valid?).and_return(true)
      end
      it { is_expected.to be_truthy }
    end
  end

  describe '#available_child_collections' do
    subject { form.available_child_collections }

    describe 'when parent is not present' do
      let(:parent) { nil }

      it { is_expected.to eq([]) }
    end

    describe 'when parent is present' do
      xit { is_expected.to eq([]) }
    end
  end
  describe '#available_parent_collections' do
    subject { form.available_parent_collections }

    describe 'when parent is not present' do
      let(:child) { nil }

      it { is_expected.to eq([]) }
    end

    describe 'when parent is present' do
      xit { is_expected.to eq([]) }
    end
  end
end
