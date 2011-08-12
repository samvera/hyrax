require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


# See cucumber tests (ie. /features/edit_document.feature) for more tests, including ones that test the edit method & view
# You can run the cucumber tests with 
#
# cucumber --tags @edit
# or
# rake cucumber

describe PermissionsController do
  describe "index" do
    it "should retrieve the object's rightsMetadata datastream as a Hydra::RightsMetadata object and render the _index partial" do
    end
  end
  describe "show" do
    it"should render different partial based on the permission type" do
      pending
      renders "permissions/edit_individual"
      renders "permissions/edit_group"
    end
  end
  describe "edit" do
  end
  describe "new" do
    it "should render the _new partial"
  end
  describe "create" do
    it "should create a new permissions entry" do
      stub_solrizer = stub("solrizer", :solrize)
      Solrizer::Fedora::Solrizer.stubs(:new).returns(stub_solrizer)
      mock_ds = mock("Datastream")
      Hydra::RightsMetadata.stubs(:from_xml).returns(mock_ds)
      mock_ds.expects(:permissions).with({"person" => "_person_id_"}, "read")
      # mock_ds.expects(:update_permissions).with({"person"=>{"_person_id_"=>"read"}})
      mock_ds.stubs(:content)
      mock_ds.stubs(:pid=)
      mock_ds.stubs(:dsid=)
      mock_ds.stubs(:save)
      mock_object = mock("object")
      mock_object.stubs(:datastreams_in_memory).returns({"rightsMetadata"=>mock_ds})
      
      ActiveFedora::Base.expects(:load_instance).with("_pid_").returns(mock_object)

      post :create, :id=>"_pid_", :permission => {"actor_id"=>"_person_id_","actor_type"=>"person","access_level"=>"read"}      
      # post :create, :asset_id=>"_pid_", :permission => {"person"=>"_person_id_","level"=>"read"}
    end
    it "should rely on .update method"
  end
  describe "update" do
    it "should call Hydra::RightsMetadata properties setter" do
      stub_solrizer = stub("solrizer", :solrize)
      Solrizer::Fedora::Solrizer.stubs(:new).returns(stub_solrizer)
      mock_ds = mock("Datastream")
      Hydra::RightsMetadata.stubs(:from_xml).returns(mock_ds)
      mock_ds.expects(:update_permissions).with({"group" => {"_group_id_"=>"discover"}})
      mock_ds.stubs(:content)
      mock_ds.stubs(:pid=)
      mock_ds.stubs(:dsid=)
      mock_ds.stubs(:save)
      mock_object = mock("object")
      mock_object.stubs(:datastreams_in_memory).returns({"rightsMetadata"=>mock_ds})
      
      ActiveFedora::Base.expects(:load_instance).with("_pid_").returns(mock_object)
      # must define new routes that can handle url like this
      # /assets/_pid_/permissions/group/_group_id_
      # /assets/:asset_id/permissions/:actor_type/:actor_id
      
      # this is what currently works 
      # post :update, :asset_id=>"_pid_", :actor_type=>"group", :actor_id=>"_group_id_", :permission => {"group"=>"_group_id_","level"=>"discover"}
      
      post :update, :id=>"_pid_", :permission => {"group"=>{"_group_id_"=>"discover"}}
    end
    it "should add a rightsMetadata datastream if it doesn't exist"
    it "should not cause the metadata to be indexed twice" do
      # should load the object as ActiveFedora::Base, initialize the rightsMetadata datastream as Hydra::RightsMetadata, update the datastream, save the datastream, and tell Solrizer to re-index the object from pid
      # re-indexing from pid rather than passing in the current object prevents double-indexing of the edited metadatata datastream
    end
  end
end
