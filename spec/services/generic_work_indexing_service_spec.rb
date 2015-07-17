require 'spec_helper'

describe CurationConcerns::GenericWorkIndexingService do
  # TODO generic_file_ids returns an empty set unless you persist the work
  let(:generic_work) { GenericWork.create { |gf| gf.apply_depositor_metadata('jcoyne') } }
  let(:service) { described_class.new(generic_work) }

  subject { service.generate_solr_document }

  context "with generic_files" do
    let(:generic_file) { GenericFile.new(id: '123') { |gf| gf.apply_depositor_metadata('jcoyne') } }
    before do
      generic_work.members << generic_file
    end

    it "indexes files" do
      expect(subject['generic_file_ids_ssim']).to eq ['123']
      expect(subject['generic_type_sim']).to eq ['Work']
    end
  end
end
