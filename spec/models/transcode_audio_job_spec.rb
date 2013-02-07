require 'spec_helper'

describe TranscodeAudioJob, :if => Sufia::Engine.config.enable_ffmpeg do
  before do
    @generic_file = GenericFile.new
    @generic_file.apply_depositor_metadata('jcoyne@example.com')
    @generic_file.stub(:characterize_if_changed).and_yield
  end

  after do
    @generic_file.delete
  end

  subject { TranscodeAudioJob.new(@generic_file.id, 'content')}


  describe "with a wav file" do
    before do
      @generic_file.add_file_datastream(File.new(fixture_path + '/piano_note.wav'), :dsid=>'content')
      @generic_file.save!
    end

    it "should transcode to mp3 and ogg" do
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

  describe "with an mp3 file" do
    before do
      @generic_file.add_file_datastream(File.new(fixture_path + '/sufia/sufia_test5.mp3'), :dsid=>'content')
      @generic_file.characterize # so that the mime_type is set
      @generic_file.save!
    end

    it "should copy the content to the mp3 datastream and transcode to ogg" do
      subject.run
      reloaded = GenericFile.find(@generic_file.pid)
      derivative = reloaded.datastreams['mp3']
      derivative.should_not be_nil
      derivative.content.should == reloaded.content.content
      derivative.mimeType.should == 'audio/mp3'

      derivative2 = reloaded.datastreams['ogg']
      derivative2.should_not be_nil
      derivative2.content.should_not be_nil
      derivative2.mimeType.should == 'audio/ogg'
    end
  end
  describe "with an ogg file" do
    before do
      @generic_file.add_file_datastream(File.new(fixture_path + '/Example.ogg'), :dsid=>'content')
      @generic_file.characterize # so that the mime_type is set
      @generic_file.save!
    end

    it "should copy the content to the ogg datastream and transcode to mp3" do
      subject.run
      reloaded = GenericFile.find(@generic_file.pid)
      derivative = reloaded.datastreams['mp3']
      derivative.should_not be_nil
      derivative.content.should_not be_nil
      derivative.mimeType.should == 'audio/mp3'

      derivative2 = reloaded.datastreams['ogg']
      derivative2.should_not be_nil
      #derivative2.content.should == reloaded.content.content
      derivative2.mimeType.should == 'audio/ogg'
    end
  end
end

