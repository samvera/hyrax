require 'spec_helper'

describe CurationConcerns::CreateDerivativesService do
  before do
    @ffmpeg_enabled = CurationConcerns.config.enable_ffmpeg
    CurationConcerns.config.enable_ffmpeg = true
    allow(ActiveFedora::Base).to receive(:find).with('123').and_return(generic_file)
    allow(generic_file.content).to receive(:has_content?).and_return(true)
  end
  let(:generic_file) { GenericFile.new }

  after do
    CurationConcerns.config.enable_ffmpeg = @ffmpeg_enabled
  end

  subject { CreateDerivativesJob.new('123') }

  # Should be refactored to test CurationConcerns::CreateDerivativesService
  it "should run the derivative creation service and save" do
    expect(CurationConcerns::CreateDerivativesService).to receive(:run).with(generic_file)
    expect(generic_file).to receive(:save)
    subject.run
  end
end
