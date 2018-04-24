RSpec.describe Hyrax::Forms::Admin::CollectionTypeForm do
  let(:collection_type) { build(:collection_type) }
  let(:form) { described_class.new }

  subject { form }

  it { is_expected.to delegate_method(:title).to(:collection_type) }
  it { is_expected.to delegate_method(:description).to(:collection_type) }
  it { is_expected.to delegate_method(:nestable).to(:collection_type) }
  it { is_expected.to delegate_method(:brandable).to(:collection_type) }
  it { is_expected.to delegate_method(:sharable).to(:collection_type) }
  it { is_expected.to delegate_method(:share_applies_to_new_works).to(:collection_type) }
  it { is_expected.to delegate_method(:require_membership).to(:collection_type) }
  it { is_expected.to delegate_method(:allow_multiple_membership).to(:collection_type) }
  it { is_expected.to delegate_method(:assigns_workflow).to(:collection_type) }
  it { is_expected.to delegate_method(:assigns_visibility).to(:collection_type) }
  it { is_expected.to delegate_method(:id).to(:collection_type) }
  it { is_expected.to delegate_method(:persisted?).to(:collection_type) }
  it { is_expected.to delegate_method(:collections?).to(:collection_type) }
  it { is_expected.to delegate_method(:admin_set?).to(:collection_type) }
  it { is_expected.to delegate_method(:user_collection?).to(:collection_type) }
  it { is_expected.to delegate_method(:badge_color).to(:collection_type) }

  describe '#all_settings_disabled?' do
    before do
      allow(form).to receive(:collection_type).and_return(collection_type)
    end

    context 'when editing admin set collection type' do
      before do
        allow(form).to receive(:admin_set?).and_return(true)
      end

      it 'returns true' do
        expect(subject.all_settings_disabled?).to be true
      end
    end

    context 'when editing user collection type' do
      before do
        allow(form).to receive(:user_collection?).and_return(true)
      end

      it 'returns true' do
        expect(subject.all_settings_disabled?).to be true
      end
    end

    context 'when there are collections of this collection type' do
      before do
        allow(form).to receive(:collections?).and_return(true)
      end

      it 'returns true' do
        expect(subject.all_settings_disabled?).to be true
      end
    end

    context 'when not admin set collection type AND not user collection type AND there are no collections of this collection type' do
      before do
        allow(form).to receive(:admin_set?).and_return(false)
        allow(form).to receive(:user_collection?).and_return(false)
        allow(form).to receive(:collections?).and_return(false)
      end

      it 'returns false' do
        expect(subject.all_settings_disabled?).to be false
      end
    end
  end

  describe 'share_options_disabled?' do
    before do
      allow(form).to receive(:collection_type).and_return(collection_type)
    end

    context 'when all settings are disabled' do
      before do
        allow(form).to receive(:all_settings_disabled?).and_return(true)
      end

      it 'returns true' do
        expect(subject.share_options_disabled?).to be true
      end
    end

    context 'when collection type sharable setting is off' do
      before do
        allow(form).to receive(:sharable).and_return(false)
      end

      it 'returns true' do
        expect(subject.share_options_disabled?).to be true
      end
    end

    context 'when all options are not disabled and the collection type sharable setting is on' do
      before do
        allow(form).to receive(:all_settings_disabled?).and_return(false)
        allow(form).to receive(:sharable).and_return(true)
      end

      it 'returns false' do
        expect(subject.share_options_disabled?).to be false
      end
    end
  end
end
