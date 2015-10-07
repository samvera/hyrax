require 'spec_helper'

describe CharacterizeJob do
  let(:file_set) { FileSet.new(id: file_set_id) }
  let(:file_set_id) { 'abc123' }
  let(:filename) { double }

  before do
    allow(ActiveFedora::Base).to receive(:find).with(file_set_id).and_return(file_set)
  end

  it 'runs CurationConcerns::CharacterizationService and creates a CreateDerivativesJob' do
    expect(CurationConcerns::CharacterizationService).to receive(:run).with(file_set, filename)
    expect(file_set).to receive(:save)
    expect(FulltextExtractionJob).to receive(:perform_later).with(file_set_id, filename)
    expect(CreateDerivativesJob).to receive(:perform_later).with(file_set_id, filename)
    described_class.perform_now file_set_id, filename
  end
end
