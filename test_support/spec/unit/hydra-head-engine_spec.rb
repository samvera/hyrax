require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "hydra-head"

describe HydraHead::Engine do
  it "should be a subclass of Rails::Engine" do
    HydraHead::Engine.superclass.should == Rails::Engine
  end
end