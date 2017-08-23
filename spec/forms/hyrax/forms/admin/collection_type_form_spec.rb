RSpec.describe Hyrax::Forms::Admin::CollectionTypeForm do
<<<<<<< HEAD
  let(:form) { described_class.new }

  describe ".title" do
    subject { form.title }

    it {
      is_expected.to eq 'placeholder'
    }
  end
=======
  let(:collection_type) { build(:collection_type) }
  let(:form) { described_class.new }

  subject { form }

  it { is_expected.to delegate_method(:title).to(:collection_type) }
  it { is_expected.to delegate_method(:description).to(:collection_type) }
  it { is_expected.to delegate_method(:nestable).to(:collection_type) }
  it { is_expected.to delegate_method(:sharable).to(:collection_type) }
  it { is_expected.to delegate_method(:require_membership).to(:collection_type) }
  it { is_expected.to delegate_method(:allow_multiple_membership).to(:collection_type) }
  it { is_expected.to delegate_method(:assigns_workflow).to(:collection_type) }
  it { is_expected.to delegate_method(:assigns_visibility).to(:collection_type) }
  it { is_expected.to delegate_method(:id).to(:collection_type) }
  it { is_expected.to delegate_method(:persisted?).to(:collection_type) }
>>>>>>> d12ade881334676075d4495cbbb6c22b39c665ec
end
