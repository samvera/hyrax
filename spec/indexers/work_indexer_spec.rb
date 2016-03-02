require 'spec_helper'

describe CurationConcerns::WorkIndexer do
  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let!(:generic_work) { create(:work_with_one_file, user: user) }
  let!(:child_work) { create(:generic_work, user: user) }
  let(:service) { described_class.new(generic_work) }
  let(:file) { generic_work.file_sets.first }

  before do
    generic_work.works << child_work
    allow(CurationConcerns::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
    generic_work.representative_id = file.id
  end

  subject { service.generate_solr_document }

  it 'indexes member work and file_set ids' do
    expect(subject['member_ids_ssim']).to eq generic_work.member_ids
    expect(subject['generic_type_sim']).to eq ['Work']
    expect(subject.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
  end

  context "when thumbnail_field is configured" do
    before do
      service.thumbnail_field = 'thumbnail_url_ss'
    end
    it "uses the configured field" do
      expect(subject.fetch('thumbnail_url_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
    end
  end
end
