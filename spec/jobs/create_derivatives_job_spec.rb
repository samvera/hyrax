require 'spec_helper'

describe CreateDerivativesJob do
  before do
    @ffmpeg_enabled = Sufia.config.enable_ffmpeg
    Sufia.config.enable_ffmpeg = true
    allow(ActiveFedora::Base).to receive(:find).with('123').and_return(generic_file)
    allow(generic_file.content).to receive(:has_content?).and_return(true)
  end
  let(:generic_file) { GenericFile.new }

  after do
    Sufia.config.enable_ffmpeg = @ffmpeg_enabled
  end

  subject { CreateDerivativesJob.new('123') }

  it "should run the derivative creation service and save" do
    expect(CurationConcerns::CreateDerivativesService).to receive(:run).with(generic_file)
    expect(generic_file).to receive(:save)
    subject.run
  end
end
