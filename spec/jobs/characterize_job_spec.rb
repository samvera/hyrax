require 'spec_helper'

describe CharacterizeJob do
  include CurationConcerns::FactoryHelpers

  let(:file_set)    { FileSet.new(id: file_set_id) }
  let(:file_set_id) { 'abc12345' }
  let(:file_path)   { Rails.root + 'tmp' + 'uploads' + 'ab' + 'c1' + '23' + '45' + 'abc12345' + 'picture.png' }
  let(:filename)    { file_path.to_s }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.save!
    end
  end

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    allow(file_set).to receive(:original_file).and_return(file)
  end

  context 'when the characterization proxy content is present' do
    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      expect(file).to receive(:save!)
      expect(file_set).to receive(:update_index)
      expect(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
      described_class.perform_now(file_set, file.id)
    end
  end

  context 'when the characterization proxy content is absent' do
    before { allow(file_set).to receive(:characterization_proxy?).and_return(false) }
    it 'raises an error' do
      expect { described_class.perform_now(file_set, file.id) }.to raise_error(LoadError, 'original_file was not found')
    end
  end

  context "when the file set's work is in a collection" do
    let(:work)       { build(:generic_work) }
    let(:collection) { build(:collection) }
    before do
      allow(file_set).to receive(:parent).and_return(work)
      allow(work).to receive(:in_collections).and_return([collection])
      allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      allow(file).to receive(:save!)
      allow(file_set).to receive(:update_index)
      allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
    end
    it "reindexes the collection" do
      expect(collection).to receive(:update_index)
      described_class.perform_now(file_set, file.id)
    end
  end
end
