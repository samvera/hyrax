require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )
  
class FakeAssetsController
  include Hydra::FileAssetsHelper
end

def helper
  @fake_controller
end

describe Hydra::FileAssetsHelper do

  before(:all) do
    @fake_controller = FakeAssetsController.new
  end
  
  describe "create_and_save_file_asset_from_params" do
    it "does" do
      mock_asset = mock("asset", :save)
      sample_params = {:Filedata => "fake blob", :Filename=>"my filename"}
      helper.stubs(:params).returns( sample_params )
      
      helper.expects(:create_asset_from_params).returns(mock_asset)
      helper.expects(:add_posted_blob_to_asset).returns(mock_asset)
      
      helper.create_and_save_file_asset_from_params
    end
  end
  
  describe "create_asset_from_params" do
    it "should create a new file asset, choosing which type based on info from params hash" do
      pending
      sample_params = {:Filedata => "fake blob", :Filename=>"my_filename.wav"}
      helper.stubs(:params).returns( sample_params )
      
      helper.create_asset_from_params.should be_kind_of(AudioAsset)
    end
  end
  
  describe "asset_class_from_params"
  describe "add_posted_blob_to_asset"
  
  describe "choose_model_by_filename" do
    it "should return model classes based on filename extensions" do
      
      ["filename.wav","filename.mp3","filename.aiff"].each do |fn|
        helper.choose_model_by_filename(fn).should == AudioAsset
      end
      
      ["filename.mov","filename.flv","filename.mp4"].each do |fn|
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