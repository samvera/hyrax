# frozen_string_literal: true

RSpec.describe IiifManifestCachePrewarmJob do
  let(:work) { create(:work_with_files) }

  describe '.perform_now' do
    it 'caches a manifest'
  end
end
