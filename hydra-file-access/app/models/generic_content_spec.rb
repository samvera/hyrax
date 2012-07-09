require 'spec_helper'

describe GenericContent do
  before :all do
    @behavior = GenericContent.deprecation_behavior
    @h_behavior = Hydra::GenericContent.deprecation_behavior
    GenericContent.deprecation_behavior = :silence
    Hydra::GenericContent.deprecation_behavior = :silence
  end

  after :all do
    GenericContent.deprecation_behavior = @behavior
    Hydra::GenericContent.deprecation_behavior = @h_behavior
  end
  
  before(:each) do
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
