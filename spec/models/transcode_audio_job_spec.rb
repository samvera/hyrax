require 'spec_helper'

describe TranscodeAudioJob do
  before do
    @generic_file = GenericFile.new
    @generic_file.apply_depositor_metadata('jcoyne@example.com')
    @generic_file.add_file_datastream(File.new(fixture_path + '/piano_note.wav'), :dsid=>'content')
    @generic_file.save!
  end

  after do
    @generic_file.delete
  end

  subject { TranscodeAudioJob.new(@generic_file.id, 'content')}
  it "should put content in datastream_out" do
    subject.run
    reloaded = GenericFile.find(@generic_file.pid)
    derivative = reloaded.datastreams['mp3']
    derivative.should_not be_nil
    derivative.content.should_not be_nil
    derivative.mimeType.should == 'audio/mp3'

    derivative2 = reloaded.datastreams['ogg']
    derivative2.should_not be_nil
    derivative2.content.should_not be_nil
    derivative2.mimeType.should == 'audio/ogg'
  end
end

