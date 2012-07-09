require 'spec_helper'

describe Hydra::Controller do
  before(:all) do
    class HydraUiControllerTest
    end
  end
  after :all do
    Object.send(:remove_const, :HydraUiControllerTest)
  end

  it "should add the necessary helpers to classes that include it" do
    HydraUiControllerTest.should_receive(:helper).with(:generic_content_objects)
    HydraUiControllerTest.should_receive(:helper).with(:hydra_uploader)
    HydraUiControllerTest.stub(:before_filter)
    HydraUiControllerTest.send(:include, Hydra::UI::Controller)
  end
end
