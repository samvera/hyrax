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
      mock_fa.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid=>'bar')
      mock_fa.should_receive(:set_title_and_label).with( file_name, :only_if_blank=>true )
      helper.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      helper.add_posted_blob_to_asset(mock_fa,mock_file) # this is the deprecated 2 argument method
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
      helper.stub(:params).and_return( :Filedata=>[mock_file], :container_id=>"hydrangea:2973" )      
      mock_file.should_receive(:original_filename).and_return(file_name)
      mock_fa = mock("file asset")
      helper.should_receive(:mime_type).with(file_name).and_return("mymimetype")
      mock_fa.should_receive(:add_file_datastream).with(mock_file, :label=>file_name, :mimeType=>"mymimetype", :dsid => 'content')
      mock_fa.stub(:set_title_and_label)
      helper.add_posted_blob_to_asset(mock_fa,mock_file)
    end
  end
end
