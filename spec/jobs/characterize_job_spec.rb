# frozen_string_literal: true
RSpec.describe CharacterizeJob do
  let(:file_set_id) { 'abc12345' }
  let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
  let(:file_set) do
    FileSet.new(id: file_set_id).tap do |fs|
      allow(fs).to receive(:original_file).and_return(file)
      allow(fs).to receive(:update_index)
    end
  end
  # let(:io)          { JobIoWrapper.new(file_set_id: file_set.id, user: create(:user), path: filename) }
  let(:file) do
    Hydra::PCDM::File.new.tap do |f|
      f.content = 'foo'
      f.original_name = 'picture.png'
      f.save!
      allow(f).to receive(:save!)
    end
  end

  before do
    allow(FileSet).to receive(:find).with(file_set_id).and_return(file_set)
    allow(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
    allow(CreateDerivativesJob).to receive(:perform_later).with(file_set, file.id, filename)
  end

  context 'with valid filepath param' do
    let(:filename) { File.join(fixture_path, 'world.png') }

    it 'skips Hyrax::WorkingDirectory' do
      expect(Hyrax::WorkingDirectory).not_to receive(:find_or_retrieve)
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(file, filename)
      described_class.perform_now(file_set, file.id, filename)
    end
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
      expect { described_class.perform_now(file_set, file.id) }.to raise_error(StandardError, /original_file was not found/)
    end
  end
end
