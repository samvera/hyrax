# frozen_string_literal: true

RSpec.describe Hyrax::Redirects::Resolver do
  let(:resource_id) { 'res-1' }
  let(:work_doc)    { ::SolrDocument.new('id' => resource_id, 'has_model_ssim' => ['GenericWork']) }

  before { Hyrax::RedirectPath.delete_all }

  context 'when the path has no row' do
    it 'returns nil' do
      expect(described_class.call('/no-such-path')).to be_nil
    end
  end

  context 'when the path is blank' do
    it 'returns nil without consulting the table' do
      expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
      expect(described_class.call('')).to be_nil
    end
  end

  context 'when the row is flagged as the display URL' do
    before do
      Hyrax::RedirectPath.create!(path: '/robs-cat-study', resource_id: resource_id, display_url: true)
      allow(::SolrDocument).to receive(:find).with(resource_id).and_return(work_doc)
    end

    it 'returns a render_path pointing at the resource canonical path' do
      result = described_class.call('/robs-cat-study')
      expect(result).to be_a(Hash)
      expect(result.keys).to eq([:render_path])
      expect(result[:render_path]).to include("/concern/generic_works/#{resource_id}")
    end
  end

  context 'when the row is not display_url and a sibling display row exists' do
    before do
      Hyrax::RedirectPath.create!(path: '/handle/12345/678', resource_id: resource_id, display_url: false)
      Hyrax::RedirectPath.create!(path: '/robs-cat-study', resource_id: resource_id, display_url: true)
    end

    it 'returns a redirect_to pointing at the sibling display path' do
      expect(described_class.call('/handle/12345/678')).to eq(redirect_to: '/robs-cat-study')
    end
  end

  context 'when the row is not display_url and no sibling display row exists' do
    before do
      Hyrax::RedirectPath.create!(path: '/handle/12345/678', resource_id: resource_id, display_url: false)
      allow(::SolrDocument).to receive(:find).with(resource_id).and_return(work_doc)
    end

    it 'returns a redirect_to pointing at the resource canonical path' do
      result = described_class.call('/handle/12345/678')
      expect(result.keys).to eq([:redirect_to])
      expect(result[:redirect_to]).to include("/concern/generic_works/#{resource_id}")
    end
  end

  context 'when SolrDocument.find raises RecordNotFound' do
    before do
      Hyrax::RedirectPath.create!(path: '/orphan', resource_id: resource_id, display_url: false)
      allow(::SolrDocument).to receive(:find).with(resource_id).and_raise(Blacklight::Exceptions::RecordNotFound)
      allow(Hyrax.logger).to receive(:warn)
    end

    it 'logs and returns nil' do
      expect(described_class.call('/orphan')).to be_nil
      expect(Hyrax.logger).to have_received(:warn).with(/resolver failed/)
    end
  end
end
