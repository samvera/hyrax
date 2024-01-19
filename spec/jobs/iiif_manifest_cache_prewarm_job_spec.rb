# frozen_string_literal: true

RSpec.describe IiifManifestCachePrewarmJob do
  let(:work) { valkyrie_create(:monograph, :with_member_file_sets) }
  let(:cache_key) do
    Hyrax::CachingIiifManifestBuilder
      .new
      .send(:manifest_cache_key, presenter: Hyrax::IiifManifestPresenter.new(work))
  end

  describe '.perform_now' do
    it 'caches a manifest' do
      expect { described_class.perform_now(work) }
        .to change { Rails.cache.read(cache_key) }
        .from(nil)
        .to an_instance_of(Hash)
    end
  end
end
