require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe FileAsset do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @file_asset = FileAsset.new
    @file_asset.stubs(:create_date).returns("2008-07-02T05:09:42.015Z")
    @file_asset.stubs(:modified_date).returns("2008-09-29T21:21:52.892Z")
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @file_asset.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should include Hydra Model Methods" do
    @file_asset.class.included_modules.should include(Hydra::ModelMethods)
    @file_asset.should respond_to(:apply_depositor_metadata)
  end
  
  describe '#garbage_collect' do
    it "should delete the object if it does not have any objects asserting has_collection_member" do
      mock_non_orphan = mock("non-orphan file asset", :containers=>["foo"])
      mock_non_orphan.expects(:delete).never
      
      mock_orphan = mock("orphan file asset", :containers=>[])
      mock_orphan.expects(:delete)
        
      FileAsset.expects(:load_instance).with("_non_orphan_pid_").returns(mock_non_orphan)
      FileAsset.expects(:load_instance).with("_orphan_pid_").returns(mock_orphan)
      
      FileAsset.garbage_collect("_non_orphan_pid_")
      FileAsset.garbage_collect("_orphan_pid_")
    end
  end
  
  describe ".add_file" do
    it "should call super.add_file"
    it "should set the FileAsset's title and label to the file datastream's filename if they are currently empty"
  end
end