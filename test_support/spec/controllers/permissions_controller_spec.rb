require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::PermissionsController do
  before :all do
    @behavior = Hydra::PermissionsController.deprecation_behavior
    Hydra::PermissionsController.deprecation_behavior = :silence
  end

  after :all do
    Hydra::PermissionsController.deprecation_behavior = @behavior 
  end
  describe "create" do
    it "should create a new permissions entry" do
      # stub out permissions check
      controller.expects(:enforce_access_controls).returns(true)
      @asset = ModsAsset.create
      post :create, :asset_id=>@asset.pid, :permission => {"actor_id"=>"_person_id_","actor_type"=>"person","access_level"=>"read"}      
      ModsAsset.find(@asset.pid).rightsMetadata.individuals.should == {"_person_id_" => "read"}
    end
  end
  describe "update" do
    it "should call Hydra::RightsMetadata properties setter" do
      # stub out permissions check
      controller.expects(:enforce_access_controls).returns(true)
      @asset = ModsAsset.new
      @asset.rightsMetadata.permissions({:group=>"students"})
      @asset.save
      post :update, :asset_id=>@asset.pid, :permission => {"group"=>{"_group_id_"=>"discover"}}
      ModsAsset.find(@asset.pid).rightsMetadata.groups.should == {"_group_id_" => "discover"}
    end
    it "should restrict permissions setting to authenticated users" do
      ActiveFedora::Base.expects(:find).never
      post :update, :id => "hydrangea:fixture_mods_dataset1"
      flash[:alert].should == "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
      flash[:notice].should be_nil
      response.should be_redirect
    end
  end
end
