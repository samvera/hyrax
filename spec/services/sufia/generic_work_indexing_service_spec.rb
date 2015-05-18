require 'spec_helper'

describe Sufia::GenericWorkIndexingService do
  let(:objects) { [double(id: 'o1'), double(id: 'o2')] }

  let(:generic_work) do
    GenericWork.new
  end

  before do
    allow(generic_work).to receive(:objects).and_return(objects)
  end

  describe "#generate_solr_document" do
    subject { described_class.new(generic_work).generate_solr_document }

    it "has fields" do
      expect(subject['objects_ssim']).to eq ['o1', 'o2']
    end
  end
end
