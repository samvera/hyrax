RSpec.describe Hyrax::CollectionSearchBuilder do
  let(:scope) { double(blacklight_config: CatalogController.blacklight_config) }
  let(:builder) { described_class.new(scope) }

  describe '#sort_field' do
    subject { builder.sort_field }

    it { is_expected.to eq('title_si') }
  end

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([Collection]) }
  end
end
