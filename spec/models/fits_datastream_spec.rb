require 'spec_helper'

describe FitsDatastream, unless: $in_travis do
  describe "image" do
    before(:all) do
      @file = GenericFile.new
      @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @file.characterize
    end
    it "should have a format label" do
      expect(@file.format_label).to eq ["Portable Network Graphics"]
    end
    it "should have a mime type" do
      expect(@file.mime_type).to eq "image/png"
    end
    it "should have a file size" do
      expect(@file.file_size).to eq ["4218"]
    end
    it "should have a last modified timestamp" do
      expect(@file.last_modified).to_not be_empty
    end
    it "should have a filename" do
      expect(@file.filename).to_not be_empty
    end
    it "should have a checksum" do
      expect(@file.original_checksum).to eq ["28da6259ae5707c68708192a40b3e85c"]
    end
    it "should have a height" do
      expect(@file.height).to eq ["50"]
    end
    it "should have a width" do
      expect(@file.width).to eq ["50"]
    end
  end
  describe "video" do
    before(:all) do
      @file = GenericFile.new
      @file.add_file(File.open(fixture_path + '/sample_mpeg4.mp4'), 'content', 'sample_mpeg4.mp4')
      @file.characterize
    end
    it "should have a format label" do
      expect(@file.format_label).to eq ["ISO Media, MPEG v4 system, version 2"]
    end
    it "should have a mime type" do
      expect(@file.mime_type).to eq "video/mp4"
    end
    it "should have a file size" do
      expect(@file.file_size).to eq ["245779"]
    end
    it "should have a last modified timestamp" do
      expect(@file.last_modified).to_not be_empty
    end
    it "should have a filename" do
      expect(@file.filename).to_not be_empty
    end
    it "should have a checksum" do
      expect(@file.original_checksum).to eq ["dc77a8de8c091c19d86df74280f6feb7"]
    end
    it "should have a width" do
      expect(@file.width).to eq ["190"]
    end
    it "should have a height" do
      expect(@file.height).to eq ["240"]
    end
    it "should have a sample_rate" do
      expect(@file.sample_rate).to eq ["32000"]
    end
    it "should have a duration" do
      expect(@file.duration).to eq ["4.97 s"]
    end
    it "should have a frame_rate" do
      expect(@file.frame_rate.count).to eq 1
      expect(@file.frame_rate[0].to_f).to eq 30.0
    end
  end
end
