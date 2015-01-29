require 'spec_helper'

describe CharacterizeJob do
  before do
    allow_any_instance_of(GenericFile).to receive(:reload_on_save?).and_return(false)
    # Don't actually create the derivatives -- that is tested elsewhere
    allow_any_instance_of(GenericFile).to receive(:create_derivatives)
    @generic_file = GenericFile.create do |gf|
      gf.apply_depositor_metadata('jcoyne@example.com')
      gf.add_file(File.open(fixture_path + '/charter.docx'), path: 'content', original_name: 'charter.docx')
    end
  end

  subject { CharacterizeJob.new(@generic_file.id)}

  it 'spawns a CreateDerivatives job' do
    expect(CreateDerivativesJob).to receive(:new).with(@generic_file.id).once.and_call_original
    subject.run
  end
end
