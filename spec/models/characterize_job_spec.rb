require 'spec_helper'

describe CharacterizeJob do
  before do
    @generic_file = GenericFile.new
    @generic_file.apply_depositor_metadata('jcoyne@example.com')
    @generic_file.save!
  end

  after do
    @generic_file.delete
  end

  subject { CharacterizeJob.new(@generic_file.id)}

  describe "with a AVI (video) file" do
    before do
      @generic_file.add_file(File.open(fixture_path + '/countdown.avi'), 'content', 'countdown.avi')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job" do
      job = double("stub video job")
      if $in_travis
        # This is in place because we stub fits for travis, and the stub sets the mime to application/pdf, fixing that.
        @generic_file.stub(:mime_type).and_return('video/avi')
        ActiveFedora::Base.should_receive(:find).with(@generic_file.id, cast:true).and_return(@generic_file)
      end
      TranscodeVideoJob.should_receive(:new).with(@generic_file.id).and_return(job)
      Sufia.queue.should_receive(:push).with(job)
      subject.run
    end
    it "should create a thumbnail" do
      GenericFile.any_instance.should_receive(:create_thumbnail)
      subject.run
    end
  end

  describe "with a WAV (audio) file" do
    before do
      @generic_file.add_file(File.open(fixture_path + '/piano_note.wav'), 'content', 'piano_note.wav')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job" do
      job = double("stub audio job")
      if $in_travis
        # This is in place because we stub fits for travis, and the stub sets the mime to application/pdf, fixing that.
        @generic_file.stub(:mime_type).and_return('audio/wav')
        ActiveFedora::Base.should_receive(:find).with(@generic_file.id, cast:true).and_return(@generic_file)
      end
      TranscodeAudioJob.should_receive(:new).with(@generic_file.id).and_return(job)
      Sufia.queue.should_receive(:push).with(job)
      subject.run
    end
  end

  describe "with an mp3 (audio) file" do
    before do
      @generic_file.add_file(File.open(fixture_path + '/sufia/sufia_test5.mp3'), 'content', 'sufia_test5.mp3')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job. (we'd like ogg too)" do
      # TODO just copy the 'content' datastream to the mp3 datastream if it's an mp3, and then transcode to ogg
      job = double("stub audio job")
      if $in_travis
        # This is in place because we stub fits for travis, and the stub sets the mime to application/pdf, fixing that.
        @generic_file.stub(:mime_type).and_return('audio/mpeg')
        ActiveFedora::Base.should_receive(:find).with(@generic_file.id, cast:true).and_return(@generic_file)
      end
      TranscodeAudioJob.should_receive(:new).with(@generic_file.id).and_return(job)
      Sufia.queue.should_receive(:push).with(job)
      subject.run
    end
  end

  describe "with an jpeg2000 (image) file" do
    before do
      @generic_file.add_file(File.open(fixture_path + '/image.jp2'), 'content', 'image.jp2')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end

    it "should create a thumbnail" do
      GenericFile.any_instance.should_receive(:create_thumbnail)
      subject.run
    end
  end
end


