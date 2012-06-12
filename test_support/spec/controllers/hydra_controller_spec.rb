require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class HydraControllerTest < ActionController::Base
end
describe HydraControllerTest do
  
  after :all do
    Object.send(:remove_const, :HydraControllerTest)
  end
  
  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.expects(:helper).with(:hydra)
    HydraControllerTest.expects(:helper).with(:hydra_assets)
    HydraControllerTest.stubs(:before_filter)
    HydraControllerTest.send(:include, Hydra::Controller::ControllerBehavior)
  end
  
  describe "load_fedora_document" do
    before do
      HydraControllerTest.send(:include, Hydra::Controller::ControllerBehavior)
    end


    it "should load @document_fedora and @file_assets" do
      controller.params[:id] = 'hydrangea:fixture_mods_article1'
      controller.load_fedora_document
      
      assigns[:document_fedora].class.should == ModsAsset 
      assigns[:document_fedora].pid.should == 'hydrangea:fixture_mods_article1' 
      assigns[:file_assets].size.should == 1
      assigns[:file_assets].first["id"].should == "hydrangea:fixture_uploaded_svg1"
    end
  end
end
