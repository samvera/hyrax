require 'spec_helper'

describe FitsDatastream, :unless => $in_travis do
  describe "image" do
    before(:all) do
      @file = GenericFile.new
      @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @file.characterize
    end
    it "should have a format label" do
      @file.format_label.should == ["Portable Network Graphics"]
    end
    it "should have a mime type" do
      @file.mime_type.should == "image/png"
    end
    it "should have a file size" do
      @file.file_size.should == ["4218"]
    end
    it "should have a file size" do
      @file.file_size.should == ["4218"]
    end
    it "should have a last modified timestamp" do
      @file.last_modified.should_not be_empty
    end
    it "should have a filename" do
      @file.filename.should_not be_empty
    end
    it "should have a checksum" do
      @file.original_checksum.should == ["28da6259ae5707c68708192a40b3e85c"]
    end
    it "should have a height" do
      @file.height.should == ["50"]
    end
    it "should have a width" do
      @file.width.should == ["50"]
    end
  end
  describe "video" do
    before(:all) do
      @file = GenericFile.new
      @file.add_file(File.open(fixture_path + '/sample_mpeg4.mp4'), 'content', 'sample_mpeg4.mp4')
      @file.characterize
    end
    it "should have a format label" do
      @file.format_label.should == ["ISO Media, MPEG v4 system, version 2"]
    end
    it "should have a mime type" do
      @file.mime_type.should == "video/mp4"
    end
    it "should have a file size" do
      @file.file_size.should == ["245779"]
    end
    it "should have a last modified timestamp" do
      @file.last_modified.should_not be_empty
    end
    it "should have a filename" do
      @file.filename.should_not be_empty
    end
    it "should have a checksum" do
      @file.original_checksum.should == ["dc77a8de8c091c19d86df74280f6feb7"]
    end
    it "should have a width" do
      @file.width.should == ["190"]
    end
    it "should have a height" do
      @file.height.should == ["240"]
    end
    it "should have a sample_rate" do
      @file.sample_rate.should == ["32000"]
    end
    it "should have a duration" do
      @file.duration.should == ["4.97 s"]
    end
    it "should have a frame_rate" do
      @file.frame_rate.count.should == 1
      @file.frame_rate[0].to_f.should == 30.0
    end
  end
end
