require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HydraUploaderHelper do
  
  describe "upload_url" do
    it "should use container_id if its available" do
      helper.stubs(:params).returns(:container_id=>"foo:22")
      helper.upload_url.should == "/assets/foo:22/file_assets"
    end
    it "should assume params[\"id\"] is pid of container when container_id is not set" do
      helper.stubs(:params).returns(:controller=>"catalog", :action=>"show", :id=>"foo:25")
      helper.upload_url.should == "/assets/foo:25/file_assets"
      helper.stubs(:params).returns(:controller=>"assets", :action=>"show", :id=>"foo:25")
      helper.upload_url.should == "/assets/foo:25/file_assets"
    end
  end
  
end