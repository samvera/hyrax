require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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
      @generic_file.add_file_datastream(File.new(fixture_path + '/countdown.avi'), :dsid=>'content', :mime_type=>'video/avi')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job" do
      job = double("stub video job")
      if $in_travis
        @generic_file.stub(:video?).and_return(true)
        GenericFile.should_receive(:find).with(@generic_file.id).and_return(@generic_file)
      end
      TranscodeVideoJob.should_receive(:new).with(@generic_file.id, 'content').and_return(job)
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
      @generic_file.add_file_datastream(File.new(fixture_path + '/piano_note.wav'), :dsid=>'content', :mime_type=>'audio/wav')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job" do
      job = double("stub audio job")
      if $in_travis
        @generic_file.stub(:audio?).and_return(true)
        GenericFile.should_receive(:find).with(@generic_file.id).and_return(@generic_file)
      end
      TranscodeAudioJob.should_receive(:new).with(@generic_file.id, 'content').and_return(job)
      Sufia.queue.should_receive(:push).with(job)
      subject.run
    end
  end

  describe "with an mp3 (audio) file" do
    before do
      @generic_file.add_file_datastream(File.new(fixture_path + '/sufia/sufia_test5.mp3'), :dsid=>'content', :mime_type=>'audio/mp3')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end
    it "should create a transcode job. (we'd like ogg too)" do
      # TODO just copy the 'content' datastream to the mp3 datastream if it's an mp3, and then transcode to ogg
      job = double("stub audio job")
      if $in_travis
        @generic_file.stub(:audio?).and_return(true)
        GenericFile.should_receive(:find).with(@generic_file.id).and_return(@generic_file)
      end
      TranscodeAudioJob.should_receive(:new).with(@generic_file.id, 'content').and_return(job)
      Sufia.queue.should_receive(:push).with(job)
      subject.run
    end
  end

  describe "with an jpeg2000 (image) file" do
    before do
      @generic_file.add_file_datastream(File.new(fixture_path + '/image.jp2'), :dsid=>'content', :mime_type=>'image/jp2')
      @generic_file.stub(:characterize_if_changed).and_yield
      @generic_file.save!
    end

    it "should create a thumbnail" do
      GenericFile.any_instance.should_receive(:create_thumbnail)
      subject.run
    end
  end
end


