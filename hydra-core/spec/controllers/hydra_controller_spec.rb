require 'spec_helper'

class HydraControllerTest < ActionController::Base
end
describe HydraControllerTest do
  
  after :all do
    Object.send(:remove_const, :HydraControllerTest)
  end
  
  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.should_receive(:helper).with(:hydra)
    HydraControllerTest.should_receive(:helper).with(:hydra_assets)
    HydraControllerTest.stub(:before_filter)
    HydraControllerTest.send(:include, Hydra::Controller::ControllerBehavior)
  end
  
end
