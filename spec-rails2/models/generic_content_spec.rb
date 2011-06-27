require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe GenericContent do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @hydra_content = GenericContent.new
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @hydra_content.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should include Hydra Model Methods" do
    @hydra_content.class.included_modules.should include(Hydra::ModelMethods)
    @hydra_content.should respond_to(:apply_depositor_metadata)
  end
  
  it "should have accessors for its default datastreams of content and original" do
    @hydra_content.should respond_to(:has_content?)
    @hydra_content.should respond_to(:content)
    @hydra_content.should respond_to(:content=)
    @hydra_content.should respond_to(:has_original?)
    @hydra_content.should respond_to(:original)
    @hydra_content.should respond_to(:original=)
  end
  
end