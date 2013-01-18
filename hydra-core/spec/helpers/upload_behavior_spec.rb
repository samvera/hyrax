require 'spec_helper'

describe Hydra::Controller::UploadBehavior do

  it "should respond to datastream_id" do
    helper.should respond_to :datastream_id  ### API method, test that it's there to be overridden
  end

  describe "add_posted_blob_to_asset" do
    it "should set object title and label, relying on datastream_id to set dsId" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stub(:params).and_return( :Filedata=>[mock_file], :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_file.should_receive(:original_filename).and_return(file_name)
      helper.stub(:datastream_id).and_return('bar')
      mock_fa.should_receive(:add_file).with(mock_file, 'bar', file_name)
      helper.add_posted_blob_to_asset(mock_fa,mock_file) # this is the deprecated 2 argument method
    end
    
    it "should support submissions from swfupload" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stub(:params).and_return( :Filedata=>[mock_file], :Filename=>file_name, "container_id"=>"hydrangea:2973" )      
      mock_fa = mock("file asset")
      mock_file.should_receive(:original_filename).and_return(file_name)
      mock_fa.should_receive(:add_file).with(mock_file, 'content', file_name)
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
    it "should support submissions from single-file uploader, defaulting to dsId of content" do
      mock_file = mock("File")
      file_name = "Posted Filename.foo"
      helper.stub(:params).and_return( :Filedata=>[mock_file], :container_id=>"hydrangea:2973" )      
      mock_file.should_receive(:original_filename).and_return(file_name)
      mock_fa = mock("file asset")
      mock_fa.should_receive(:add_file).with(mock_file, 'content', file_name)
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
  end
end
