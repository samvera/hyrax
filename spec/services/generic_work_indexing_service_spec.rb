require 'spec_helper'

describe CurationConcerns::GenericWorkIndexingService do
  # TODO: generic_file_ids returns an empty set unless you persist the work
  let(:user) { create(:user) }
  let!(:generic_work) { create(:work_with_one_file, user: user) }
  let(:service) { described_class.new(generic_work) }
  let(:file) { generic_work.generic_files.first }

  before do
    allow_any_instance_of(GenericFile).to receive(:thumbnail).and_return(double)
    generic_work.representative = file.id
  end

  subject { service.generate_solr_document }

  it 'indexes files' do
    expect(subject['generic_file_ids_ssim']).to eq generic_work.member_ids
    expect(subject['generic_type_sim']).to eq ['Work']
    expect(subject.fetch('thumbnail_path_ss')).to eq "/downloads/#{file.id}?file=thumbnail"
  end
end
