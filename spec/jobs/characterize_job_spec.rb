require 'spec_helper'

describe CharacterizeJob do

  before do
    allow(ActiveFedora::Base).to receive(:find).and_return(generic_file)
    allow(CreateDerivativesJob).to receive(:new).with(generic_file.id).and_return(job)
  end

  let(:generic_file) { double(id: '123') }
  let(:job) { double }

  subject { CharacterizeJob.new(generic_file.id)}

  it 'characterizes and spawns a CreateDerivatives job' do
    expect(Sufia::CharacterizationService).to receive(:run).with(generic_file)
    expect(generic_file).to receive(:save)
    expect(Sufia.queue).to receive(:push).with(job)
    subject.run
  end
end
