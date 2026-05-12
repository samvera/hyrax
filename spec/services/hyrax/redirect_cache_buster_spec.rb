# frozen_string_literal: true

RSpec.describe Hyrax::RedirectCacheBuster do
  before { Rails.cache.clear }

  describe '.cache_key_for' do
    it 'returns the same key format the controller uses for lookups' do
      key = described_class.cache_key_for('/handle/123')
      expect(key).to eq("hyrax/redirects/#{Digest::SHA1.hexdigest('/handle/123')}")
    end
  end

  describe '.call' do
    it 'deletes the cache entry for each given path' do
      key1 = described_class.cache_key_for('/handle/1')
      key2 = described_class.cache_key_for('/handle/2')
      Rails.cache.write(key1, { 'id' => 'work-1' })
      Rails.cache.write(key2, { 'id' => 'work-2' })

      described_class.call(['/handle/1', '/handle/2'])

      expect(Rails.cache.read(key1)).to be_nil
      expect(Rails.cache.read(key2)).to be_nil
    end

    it 'normalizes paths before computing the cache key' do
      # RedirectPathNormalizer prepends "/" if missing
      key = described_class.cache_key_for('/no-leading-slash')
      Rails.cache.write(key, { 'id' => 'work-1' })

      described_class.call(['no-leading-slash'])

      expect(Rails.cache.read(key)).to be_nil
    end

    it 'accepts a single path (not wrapped in an array)' do
      key = described_class.cache_key_for('/solo')
      Rails.cache.write(key, { 'id' => 'work-1' })

      described_class.call('/solo')

      expect(Rails.cache.read(key)).to be_nil
    end

    it 'is a no-op for an empty array' do
      expect { described_class.call([]) }.not_to raise_error
    end
  end
end
