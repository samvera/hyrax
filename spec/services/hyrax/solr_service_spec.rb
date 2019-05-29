RSpec.describe Hyrax::SolrService do
  describe '.select_path' do
    it 'raises NotImplementedError' do
      expect { described_class.select_path }.to raise_error NotImplementedError
    end
  end
end
