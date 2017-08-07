RSpec.describe Hyrax::Forms::Admin::CollectionTypeForm do
  let(:form) { described_class.new }

  describe ".title" do
    subject { form.title }

    it {
      is_expected.to eq 'placeholder'
    }
  end
end
