require 'spec_helper'

describe Hydra::Controller::UploadBehavior do

  it "should respond to datastream_id" do
    helper.should respond_to :datastream_id  ### API method, test that it's there to be overridden
  end

  describe "create_and_save_file_asset_from_params" do
    it "should create the file asset, add posted blob to it and save the file asset" do
      mock_fa = mock("file asset")
      helper.stub(:params).and_return( { :Filedata => [mock_fa] } )
      mock_fa.should_receive(:save)
      helper.should_receive(:create_asset_from_file).and_return(mock_fa)
      helper.should_receive(:add_posted_blob_to_asset)
      helper.create_and_save_file_assets_from_params
    end
  end
  
  describe "add_posted_blob_to_asset" do
    it "should set object title and label, relying on datastream_id to set dsId" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stub(:params).and_return( :Filedata=>[mock_file], :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_file.should_receive(:original_filename).and_return(file_name)
      helper.stub(:datastream_id).and_return('bar')
      mock_fa.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid=>'bar')
      mock_fa.should_receive(:set_title_and_label).with( file_name, :only_if_blank=>true )
      helper.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
    
    it "should support submissions from swfupload" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stub(:params).and_return( :Filedata=>[mock_file], :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_file.should_receive(:original_filename).and_return(file_name)
      mock_fa.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid => 'content')
      mock_fa.stub(:set_title_and_label)
      helper.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
    it "should support submissions from single-file uploader, defaulting to dsId of content" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
#      helper.should_receive(:filename_from_params).and_return(file_name)
      helper.stub(:params).and_return( :Filedata=>[mock_file], :container_id=>"hydrangea:2973" )      
      mock_file.should_receive(:original_filename).and_return(file_name)
      mock_fa = mock("file asset")
      helper.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      mock_fa.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid => 'content')
      mock_fa.stub(:set_title_and_label)
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
  end
  
  describe "create_asset_from_params" do
    it "should create a new file asset and set the label from params[:Filename]" do
      helper.stub(:params).and_return( { :Filename => "Test Filename" } )
      result = helper.create_asset_from_params
      result.should be_kind_of FileAsset
      result.label.should == "Test Filename"
    end
    it "should choose model by filename" do
      pending "this is currently disabled"
      helper.should_receive(:choose_model_by_filename)
      helper.create_asset_from_params
    end
  end
  
  describe "posted_file" do
    it "should return the posted file" do
      helper.should_receive(:params).and_return(:Filedata=>"test posted file")
      helper.posted_file.should == "test posted file"
    end
    it "should return nil if no file was posted" do
      helper.posted_file.should == nil
    end
  end
  
  describe "filename_from_params" do
    it "should return the value of params[:Filename] if it was submitted" do
      helper.stub(:params).and_return(:Filename => "Test Filename")
      helper.filename_from_params.should == "Test Filename"
    end
    it "should default to using the original filename of the posted file" do
      helper.stub(:params).and_return({})
      helper.should_receive(:posted_file).and_return(mock("File", :original_filename=>"Test Original Filename"))
      helper.filename_from_params.should == "Test Original Filename"
    end
  end
  
  describe "choose_model_by_filename" do
    it "should return model classes based on filename extensions" do
      pending "This can only be enabled if/when we adopt replacements for ImageAsset, AudioAsset, etc. as default primitives."
      
      ["filename.wav","filename.mp3","filename.aiff"].each do |fn|
        helper.choose_model_by_filename(fn).should == AudioAsset
      end
      
      ["filename.mov","filename.flv","filename.mp4", "filename.m4v"].each do |fn|
        helper.choose_model_by_filename(fn).should == VideoAsset
      end
      
      ["filename.jpeg","filename.jpg","filename.gif", "filename.png"].each do |fn|
        helper.choose_model_by_filename(fn).should == ImageAsset
      end
      
      ["filename.doc","filename.pdf","filename.jp2", "filename.zip"].each do |fn|
        helper.choose_model_by_filename(fn).should == FileAsset
      end
    end
  end
end
