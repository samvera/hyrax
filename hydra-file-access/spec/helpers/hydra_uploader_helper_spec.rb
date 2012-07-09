require 'spec_helper'

describe HydraUploaderHelper do
  before :all do
    @behavior = Hydra::HydraUploaderHelperBehavior.deprecation_behavior
    Hydra::HydraUploaderHelperBehavior.deprecation_behavior = :silence
  end

  after :all do
    Hydra::HydraUploaderHelperBehavior.deprecation_behavior = @behavior
  end
  
  describe "upload_url" do
    it "should use container_id if its available" do
      helper.stub(:params).and_return(:asset_id=>"foo:22")
      helper.upload_url.should == "/hydra/assets/foo:22/file_assets"
    end
    it "should assume params[\"id\"] is pid of container when container_id is not set" do
      helper.stub(:params).and_return(:controller=>"catalog", :action=>"show", :id=>"foo:25")
      helper.upload_url.should == "/hydra/assets/foo:25/file_assets"
      helper.stub(:params).and_return(:controller=>"assets", :action=>"show", :id=>"foo:25")
      helper.upload_url.should == "/hydra/assets/foo:25/file_assets"
    end
  end
  
end
