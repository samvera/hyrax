require 'spec_helper'

describe Hydra::AccessControls::Permission do
  describe "hash-like key access" do
    let(:perm) { described_class.new(type: 'user', name: 'bob', access: 'read') }
    it "should return values" do
      perm[:type].should == 'user'
      perm[:name].should == 'bob'
      perm[:access].should == 'read'
    end
  end
  describe "#to_hash" do
    subject { described_class.new(type: 'user', name: 'bob', access: 'read') }
    its(:to_hash) { should == {type: 'user', name: 'bob', access: 'read'} }
  end
  describe "equality comparison" do
    let(:perm1) { described_class.new(type: 'user', name: 'bob', access: 'read') }
    let(:perm2) { described_class.new(type: 'user', name: 'bob', access: 'read') }
    let(:perm3) { described_class.new(type: 'user', name: 'jane', access: 'read') }
    it "should be equal if all values are equal" do
      perm1.should == perm2
    end
    it "should be unequal if some values are unequal" do
      perm1.should_not == perm3
      perm2.should_not == perm3
    end
  end
end
