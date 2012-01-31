require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')


describe Hydra::Controller do
  before(:all) do
    class HydraControllerTest
    end
  end
  after :all do
    Object.send(:remove_const, :HydraControllerTest)
  end

  it "should add the necessary helpers to classes that include it" do
    HydraControllerTest.expects(:helper).with(:hydra_fedora_metadata)
    HydraControllerTest.expects(:helper).with(:generic_content_objects)
    HydraControllerTest.expects(:helper).with(:hydra_uploader)
    HydraControllerTest.expects(:helper).with(:article_metadata)
    HydraControllerTest.stubs(:before_filter)
    HydraControllerTest.send(:include, Hydra::UI::Controller)
  end
end
