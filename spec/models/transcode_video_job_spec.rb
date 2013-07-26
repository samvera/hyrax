require 'spec_helper'

describe TranscodeVideoJob, :if => Sufia.config.enable_ffmpeg do
  before do
    @generic_file = GenericFile.new
    @generic_file.apply_depositor_metadata('jcoyne@example.com')
    @generic_file.add_file(File.open(fixture_path + '/countdown.avi'), 'content', 'countdown.avi')
    @generic_file.stub(:characterize_if_changed).and_yield
    @generic_file.mime_type = 'video/avi'
    @generic_file.save!
  end

  after do
    @generic_file.delete
  end

  subject { TranscodeVideoJob.new(@generic_file.id)}
  it "should put content in datastream_out" do
    subject.run
    reloaded = GenericFile.find(@generic_file.pid)
    derivative = reloaded.datastreams['webm']
    derivative.should_not be_nil
    derivative.content.should_not be_nil
    derivative.mimeType.should == 'video/webm'

    derivative2 = reloaded.datastreams['mp4']
    derivative2.should_not be_nil
    derivative2.content.should_not be_nil
    derivative2.mimeType.should == 'video/mp4'
  end
end
