require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Hydra::Controller do
  before(:all) do
    class HydraControllerTest < ApplicationController
    end
  end
  
  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.expects(:helper).with(:hydra)
    HydraControllerTest.expects(:helper).with(:hydra_assets)
    HydraControllerTest.stubs(:before_filter)
    HydraControllerTest.send(:include, Hydra::Controller)
  end
  
  describe "load_fedora_document" do

    it "should load @document_fedora and @file_assets" do
      # controller.stubs(:params).returns({:id=>"foo:id"})
      # stub_base_object = stub("Base Object")
      # ActiveFedora::ContentModel.expects(:known_models_for).with( stub_base_object ).returns( [ModsAsset] )
      # stub_mods_asset = stub("MODS Asset")
      # stub_mods_asset.expects(:file_objects).with(:response_format=>:solr).returns("file assets response")
      
      # Note: Had to stub Fedora::Repository.instance.find_model rather than stubbing ActiveFedora::Base.load_instance and ModsAsset.load_instance because 
      # Mocha was not unstubbing the ModsAsset class
      #
      # ActiveFedora::Base.stubs(:load_instance).with("foo:id").returns( stub_base_object )
      # ModsAsset.stubs(:load_instance).with("foo:id").returns( stub_mods_asset )
      # Fedora::Repository.instance.expects(:find_model).with("foo:id", ActiveFedora::Base).returns( stub_base_object )
      # Fedora::Repository.instance.expects(:find_model).with("foo:id", ModsAsset).returns( stub_mods_asset )
      controller = HydraControllerTest.new 
      controller.expects(:params).returns({:id=>'hydrangea:fixture_mods_article1'})
      controller.load_fedora_document
      
      assigns[:document_fedora].class.should == ModsAsset 
      assigns[:document_fedora].pid.should == 'hydrangea:fixture_mods_article1' 
      assigns[:file_assets].class.should == Solr::Response::Standard
      assigns[:file_assets].hits.size.should == 1
      assigns[:file_assets].hits.first["id"].should == "hydrangea:fixture_uploaded_svg1"
    end
  end
end
