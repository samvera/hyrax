require 'spec_helper'

describe CurationConcerns::GenericWorkIndexingService do
  # TODO: generic_file_ids returns an empty set unless you persist the work
  let(:user) { FactoryGirl.create(:user) }
  let!(:generic_work) { FactoryGirl.create(:work_with_one_file, user: user) }
  let(:service) { described_class.new(generic_work) }

  subject { service.generate_solr_document }

  context 'with a generic_file' do
    it 'indexes files' do
      expect(subject['generic_file_ids_ssim']).to eq generic_work.member_ids
      expect(subject['generic_type_sim']).to eq ['Work']
    end
  end
end
