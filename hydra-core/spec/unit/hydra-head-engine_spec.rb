require 'spec_helper'

describe HydraHead::Engine do
  it "should be a subclass of Rails::Engine" do
    expect(HydraHead::Engine.superclass).to eq Rails::Engine
  end
end
