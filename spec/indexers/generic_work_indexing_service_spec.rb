require 'spec_helper'

describe CurationConcerns::WorkIndexingService do
  # TODO: file_set_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let!(:generic_work) { create(:work_with_one_file, user: user) }
  let(:service) { described_class.new(generic_work) }
  let(:file) { generic_work.file_sets.first }

  before do
    allow(CurationConcerns::ThumbnailPathService).to receive(:call).and_return("/downloads/#{file.id}?file=thumbnail")
    generic_work.representative = file.id
  end

  subject { service.generate_solr_document }

  it 'indexes files' do
    expect(subject['file_set_ids_ssim']).to eq generic_work.member_ids
    expect(subject['generic_type_sim']).to eq ['Work']
    expect(subject.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
  end
end
