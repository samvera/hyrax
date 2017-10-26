RSpec.describe Hyrax::IndexThumbnails do
  subject(:solr_document) { service.to_solr }

  let(:user) { create(:user) }
  let(:service) { described_class.new(resource: work) }
  let(:work) { create_for_repository(:work_with_one_file, member_ids: [file.id]) }
  let(:file) { create_for_repository(:file_set) }

  before do
    allow(Hyrax::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
    work.representative_id = file.id
    work.thumbnail_id = file.id
  end

  it 'indexes thumbnail path' do
    expect(solr_document.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
  end

  context 'when thumbnail_field is configured' do
    before do
      service.thumbnail_field = 'thumbnail_url_ss'
    end

    it 'uses the configured field' do
      expect(solr_document.fetch('thumbnail_url_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
    end
  end
end
