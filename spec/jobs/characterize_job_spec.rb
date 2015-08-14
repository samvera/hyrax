require 'spec_helper'

describe CharacterizeJob do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  let(:generic_file) do
    GenericFile.create do |file|
      file.apply_depositor_metadata(user)
      Hydra::Works::AddFileToGenericFile.call(file, File.open(fixture_file_path('charter.docx')), :original_file)
    end
  end

  subject { described_class.new(generic_file.id) }

  # Now that CreateDerivativesJob calls generic_file.create_derivatives directly
  # this test needs to be travis exempt.
  it 'runs CurationConcerns::CharacterizationService that spawns a CreateDerivativesJob', unless: $in_travis do
    expect(CurationConcerns::CharacterizationService).to receive(:run).with(generic_file)
    expect(CreateDerivativesJob).to receive(:new).with(generic_file.id).once.and_call_original
    subject.run
  end
end
