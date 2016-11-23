require 'spec_helper'

describe Sufia::Arkivo do
  describe '.config' do
    it 'returns a hash with the :url key' do
      expect(described_class.config).to have_key(:url)
    end
  end
  describe '.new_subscription_url' do
    it 'returns a string' do
      expect(described_class.new_subscription_url).to eq '/api/subscription'
    end
  end
end
