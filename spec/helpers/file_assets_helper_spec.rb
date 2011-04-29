require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::FileAssetsHelper do
  describe "create_and_save_file_asset_from_params" do
    it "should create the file asset, add posted blob to it and save the file asset" do
      helper.stubs(:params).returns( { :Filedata => "" } )      
      mock_fa = mock("file asset")
      mock_fa.expects(:save)
      helper.expects(:create_asset_from_params).returns(mock_fa)
      helper.expects(:add_posted_blob_to_asset)
      helper.create_and_save_file_asset_from_params
    end
  end
  
  describe "add_posted_blob_to_asset" do
    it "should set object title and label" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stubs(:params).returns( :Filedata=>mock_file, :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_fa.expects(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype")
      mock_fa.expects(:set_title_and_label).with( file_name, :only_if_blank=>true )
      helper.expects(:mime_type).with(file_name).returns("mymimetype")
      helper.add_posted_blob_to_asset(mock_fa)
    end
    
    it "should support submissions from swfupload" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stubs(:params).returns( :Filedata=>mock_file, :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_fa.expects(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype")
      mock_fa.stubs(:set_title_and_label)
      helper.expects(:mime_type).with(file_name).returns("mymimetype")
      helper.add_posted_blob_to_asset(mock_fa)
    end
    it "should support submissions from single-file uploader" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.expects(:filename_from_params).returns(file_name)
      helper.stubs(:params).returns( :Filedata=>mock_file, :container_id=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      helper.expects(:mime_type).with(file_name).returns("mymimetype")
      mock_fa.expects(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype")
      mock_fa.stubs(:set_title_and_label)
      helper.add_posted_blob_to_asset(mock_fa)
    end
  end
  
  describe "create_asset_from_params" do
    it "should create a new file asset and set the label from params[:Filename]" do
      helper.stubs(:params).returns( { :Filename => "Test Filename" } )
      result = helper.create_asset_from_params
      result.should be_kind_of FileAsset
      result.label.should == "Test Filename"
    end
    it "should choose model by filename" do
      pending "this is currently disabled"
      helper.expects(:choose_model_by_filename)
      helper.create_asset_from_params
    end
  end
  
  describe "posted_file" do
    it "should return the posted file" do
      helper.expects(:params).returns(:Filedata=>"test posted file")
      helper.posted_file.should == "test posted file"
    end
    it "should return nil if no file was posted" do
      helper.posted_file.should == nil
    end
  end
  
  describe "filename_from_params" do
    it "should return the value of params[:Filename] if it was submitted" do
      helper.stubs(:params).returns(:Filename => "Test Filename")
      helper.filename_from_params.should == "Test Filename"
    end
    it "should default to using the original filename of the posted file" do
      helper.stubs(:params).returns({})
      helper.expects(:posted_file).returns(mock("File", :original_filename=>"Test Original Filename"))
      helper.filename_from_params.should == "Test Original Filename"
    end
  end
  
  describe "choose_model_by_filename" do
    it "should attempt to guess at type and set model accordingly" do
      helper.choose_model_by_filename("meow.mp3").should == AudioAsset
      helper.choose_model_by_filename("meow.wav").should == AudioAsset
      helper.choose_model_by_filename("meow.aiff").should == AudioAsset
      
      helper.choose_model_by_filename("meow.mov").should == VideoAsset
      helper.choose_model_by_filename("meow.flv").should == VideoAsset
      helper.choose_model_by_filename("meow.m4v").should == VideoAsset
      
      helper.choose_model_by_filename("meow.jpg").should == ImageAsset
      helper.choose_model_by_filename("meow.jpeg").should == ImageAsset
      helper.choose_model_by_filename("meow.png").should == ImageAsset
      helper.choose_model_by_filename("meow.gif").should == ImageAsset
    end
  end
end