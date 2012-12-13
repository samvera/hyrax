require 'spec_helper'

describe TranscodeVideoJob do
  before do
    @generic_file = GenericFile.new(:terms_of_service=>'1')
    @generic_file.apply_depositor_metadata('jcoyne@example.com')
    @generic_file.add_file_datastream(File.new(fixture_path + '/countdown.avi'), :dsid=>'content')
    @generic_file.save!
  end

  after do
    @generic_file.delete
  end

  subject { TranscodeVideoJob.new(@generic_file.id, 'content')}
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

