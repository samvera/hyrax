require 'spec_helper'

describe CharacterizeJob do
  include CurationConcerns::FactoryHelpers

  let(:file_set)    { FileSet.new(id: file_set_id) }
  let(:file_set_id) { 'abc123' }
  let(:filename)    { double }
  let(:file)        { mock_file_factory }

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    allow(file_set).to receive(:original_file).and_return(file)
  end

  context 'when the characterization proxy content is present' do
    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      expect(file).to receive(:save!)
      expect(file_set).to receive(:update_index)
      expect(CreateDerivativesJob).to receive(:perform_later).with(file_set, filename)
      described_class.perform_now(file_set, filename)
    end
  end

  context 'when the characterization proxy content is absent' do
    before { allow(file_set).to receive(:characterization_proxy?).and_return(false) }
    it 'raises an error' do
      expect { described_class.perform_now(file_set, filename) }.to raise_error(LoadError, 'original_file was not found')
    end
  end
end
