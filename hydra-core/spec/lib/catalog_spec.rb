require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::Controller::CatalogControllerBehavior do
  
  before(:all) do
    @behavior = Hydra::Controller::CatalogControllerBehavior.deprecation_behavior
    Hydra::Controller::CatalogControllerBehavior.deprecation_behavior = :silence

    class CatalogTest < ApplicationController
      include Hydra::Controller::CatalogControllerBehavior
    end
    @catalog = CatalogTest.new
  end

  after(:all) do
    Hydra::Controller::CatalogControllerBehavior.deprecation_behavior = @behavior
  end
  
  it "should extend classes with the necessary Hydra modules" do
    CatalogTest.included_modules.should include(Hydra::AccessControlsEnforcement)
  end
  
end
