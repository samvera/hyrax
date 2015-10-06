require 'spec_helper'

describe CurationConcerns::CreateDerivativesJob do
  before do
    @ffmpeg_enabled = CurationConcerns.config.enable_ffmpeg
    CurationConcerns.config.enable_ffmpeg = true
    allow(ActiveFedora::Base).to receive(:find).with('123').and_return(file_set)
    allow(file_set).to receive(:mime_type).and_return('audio/x-wav')
    allow(file_set).to receive(:id).and_return('123')
  end

  let(:file_set) { FileSet.new }

  after do
    CurationConcerns.config.enable_ffmpeg = @ffmpeg_enabled
  end

  context "with a file name" do
    it 'calls create_derivatives and save on a file set' do
      expect(Hydra::Derivatives::AudioDerivatives).to receive(:create)
      CreateDerivativesJob.perform_now('123', 'spec/fixtures/piano_note.wav')
    end
  end
end
