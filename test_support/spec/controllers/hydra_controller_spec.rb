require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Hydra::Controller do
  before(:all) do
    class HydraControllerTest
    end
  end
  
  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.expects(:helper).with(:hydra)
    HydraControllerTest.expects(:helper).with(:hydra_assets)
    HydraControllerTest.stubs(:before_filter)
    HydraControllerTest.send(:include, Hydra::Controller)
  end
end