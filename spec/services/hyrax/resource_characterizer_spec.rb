RSpec.describe Hyrax::ResourceCharacterizer do
  subject(:characterizer) { described_class.new(source: resource) }

  before do
    allow(Hyrax::FileSet).to receive(:find).with(resource.id).and_return(resource)
    allow(Hydra::Works::CharacterizationService).to receive(:run)
    allow(Hyrax.persister).to receive(:save)
    allow(CreateDerivativesJob).to receive(:perform_later)
  end

  context 'with a complete Valkyrie FileSet' do
    let(:resource) { FactoryBot.create(:file_set, content: File.open(fixture_path + '/world.png')).valkyrie_resource }

    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect(Hydra::Works::CharacterizationService).to receive(:run).with(resource.original_file, anything)
      expect(CreateDerivativesJob).to receive(:perform_later).with(resource, resource.original_file.id, anything)
      expect(Hyrax.persister).to receive(:save).twice
      characterizer.characterize
    end
  end

  context 'without a complete Valkyrie FileSet' do
    let(:resource) { FactoryBot.create(:file_set).valkyrie_resource }

    before { allow(resource).to receive(:characterization_proxy?).and_return(false) }

    it 'runs Hydra::Works::CharacterizationService and creates a CreateDerivativesJob' do
      expect { characterizer.characterize }.to raise_error(StandardError, /original_file was not found/)
    end
  end
end
