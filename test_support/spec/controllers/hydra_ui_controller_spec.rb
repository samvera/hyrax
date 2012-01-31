require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Hydra::Controller do
  before(:all) do
    class HydraUiControllerTest
    end
  end
  after :all do
    Object.send(:remove_const, :HydraUiControllerTest)
  end

  it "should add the necessary helpers to classes that include it" do
    HydraUiControllerTest.expects(:helper).with(:hydra_fedora_metadata)
    HydraUiControllerTest.expects(:helper).with(:generic_content_objects)
    HydraUiControllerTest.expects(:helper).with(:hydra_uploader)
    HydraUiControllerTest.expects(:helper).with(:article_metadata)
    HydraUiControllerTest.stubs(:before_filter)
    HydraUiControllerTest.send(:include, Hydra::UI::Controller)
  end
end
