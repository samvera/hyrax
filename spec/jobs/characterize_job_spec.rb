require 'spec_helper'

describe CharacterizeJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(user)
      Hydra::Works::AddFileToGenericFile.call(file, fixture_path + '/charter.docx', :original_file, original_name: 'charter.docx')
    end
  end

  subject { CharacterizeJob.new(generic_file.id) }

  it 'spawns a CreateDerivatives job' do
    expect(CurationConcerns::CharacterizationService).to receive(:run).with(generic_file)
    expect(CurationConcerns::CreateDerivativesService).to receive(:run).with(generic_file)
    subject.run
  end
end
