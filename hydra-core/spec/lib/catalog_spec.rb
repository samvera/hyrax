require 'spec_helper'

describe Hydra::Controller::ControllerBehavior do

  before do
    class CatalogTest < ApplicationController
      include Hydra::Controller::ControllerBehavior
    end
  end

  it "should extend classes with the necessary Hydra modules" do
    expect(CatalogTest.included_modules).to include(Hydra::AccessControlsEnforcement)
  end

end
