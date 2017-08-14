RSpec.describe Hyrax::Forms::Admin::CollectionTypeForm do
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
end
