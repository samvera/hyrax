require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Hydra::Controller do
  before(:all) do
    class HydraControllerTest
    end
  end
  
  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.expects(:helper).with(:hydra_assets)
    HydraControllerTest.expects(:helper).with(:hydra_fedora_metadata)
    HydraControllerTest.send(:include, Hydra::Controller)
  end
end