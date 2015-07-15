require 'spec_helper'

describe CurationConcerns::GenericWorkIndexingService do
  let(:generic_work) { GenericWork.create { |gf| gf.apply_depositor_metadata('jcoyne') } }
  let(:service) { described_class.new(generic_work) }

  let(:generic_file) { GenericFile.new(id: '123') { |gf| gf.apply_depositor_metadata('jcoyne') } }
  subject { service.generate_solr_document }

  context "with generic_files" do
    before do
      generic_work.members << generic_file
    end

    it "indexes files" do
      expect(subject['generic_file_ids_ssim']).to eq ['123']
    end
  end
end
