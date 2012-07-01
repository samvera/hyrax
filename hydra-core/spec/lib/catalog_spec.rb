require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::Controller::ControllerBehavior do
  
  before(:all) do
    class CatalogTest < ApplicationController
      include Hydra::Controller::ControllerBehavior
    end
    @catalog = CatalogTest.new
  end

  after(:all) do
    Hydra::Controller::ControllerBehavior.deprecation_behavior = @behavior
  end
  
  it "should extend classes with the necessary Hydra modules" do
    CatalogTest.included_modules.should include(Hydra::AccessControlsEnforcement)
  end
  
end
