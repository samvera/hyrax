RSpec.describe Hyrax::Analytics::Base do
  describe '.connection' do
    it 'is unimplemented' do
      expect { described_class.connection }.to raise_error NotImplementedError
    end
  end

  describe '.pageviews' do
    it 'is unimplemented' do
      expect { described_class.pageviews("2018-02-16", nil) }.to raise_error NotImplementedError
    end
  end

  describe '.downloads' do
    it 'is unimplemented' do
      expect { described_class.downloads("2018-02-16", nil) }.to raise_error NotImplementedError
    end
  end

  describe '.unique_visitors' do
    it 'is unimplemented' do
      expect { described_class.unique_visitors("2018-02-16") }.to raise_error NotImplementedError
    end
  end

  describe '.returning_visitors' do
    it 'is unimplemented' do
      expect { described_class.returning_visitors("2018-02-16") }.to raise_error NotImplementedError
    end
  end
end
