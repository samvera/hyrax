require 'spec_helper'

describe CurationConcerns::CreateDerivativesJob do
  before do
    @ffmpeg_enabled = CurationConcerns.config.enable_ffmpeg
    CurationConcerns.config.enable_ffmpeg = true
    allow(ActiveFedora::Base).to receive(:find).with('123').and_return(generic_file)
    allow(generic_file).to receive(:original_file).and_return(double('orignal_file', has_content?: true))
  end
  let(:generic_file) { GenericFile.new }

  after do
    CurationConcerns.config.enable_ffmpeg = @ffmpeg_enabled
  end

  it 'calls create_derivatives and save on a generic_file' do
    expect(generic_file).to receive(:create_derivatives)
    expect(generic_file).to receive(:save)
    CreateDerivativesJob.perform_now('123')
  end
end
