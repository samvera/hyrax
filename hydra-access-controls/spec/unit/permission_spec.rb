require 'spec_helper'

describe Hydra::AccessControls::Permission do

  describe "an initialized instance" do
    let(:permission) { described_class.new(type: 'person', name: 'bob', access: 'read') }

    it "should set predicates" do
      expect(permission.agent.first.rdf_subject).to eq ::RDF::URI.new('http://projecthydra.org/ns/auth/person#bob')
      expect(permission.mode.first.rdf_subject).to eq ACL.Read
    end

    describe "#to_hash" do
      subject { permission.to_hash }
      it { should eq(type: 'person', name: 'bob', access: 'read') }
    end

    describe "#agent_name" do
      subject { permission.agent_name }
      it { should eq 'bob' }
    end

    describe "#access" do
      subject { permission.access }
      it { should eq 'read' }
    end

    describe "#type" do
      subject { permission.type }
      it { should eq 'person' }
    end
  end

  describe "equality comparison" do
    let(:perm1) { described_class.new(type: 'person', name: 'bob', access: 'read') }
    let(:perm2) { described_class.new(type: 'person', name: 'bob', access: 'read') }
    let(:perm3) { described_class.new(type: 'person', name: 'jane', access: 'read') }

    it "should be equal if all values are equal" do
      expect(perm1).to eq perm2
    end

    it "should be unequal if some values are unequal" do
      expect(perm1).to_not eq perm3
      expect(perm2).to_not eq perm3
    end
  end
end
