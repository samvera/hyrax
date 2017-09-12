RSpec.describe Hyrax::Dashboard::AllCollectionsSearchBuilder do
  let(:scope) { double(blacklight_config: CatalogController.blacklight_config) }
  let(:builder) { described_class.new(scope) }

  describe '#models' do
    subject { builder.models }

    it { is_expected.to eq([AdminSet, Collection]) }
  end
end
