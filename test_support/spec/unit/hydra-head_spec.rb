require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "hydra-head"

describe HydraHead do
  it "should be valid" do
    HydraHead.should be_a(Module)
  end
end