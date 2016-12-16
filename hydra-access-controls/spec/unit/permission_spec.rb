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

  describe "URI escaping" do
    let(:permission) { described_class.new(type: 'person', name: 'john doe', access: 'read') }
    let(:permission2) { described_class.new(type: 'group', name: 'hydra devs', access: 'read') }

    it "should escape agent when building" do
      expect(permission.agent.first.rdf_subject.to_s).to eq 'http://projecthydra.org/ns/auth/person#john%20doe'
      expect(permission2.agent.first.rdf_subject.to_s).to eq 'http://projecthydra.org/ns/auth/group#hydra%20devs'
    end

    it "should unescape agent when parsing" do
      expect(permission.agent_name).to eq 'john doe'
      expect(permission2.agent_name).to eq 'hydra devs'
    end

    context 'with a User instance passed as :name argument' do
      let(:permission) { described_class.new(type: 'person', name: user, access: 'read') }
      let(:user) { FactoryGirl.build(:archivist, email: 'archivist1@example.com') }

      it "uses string and escape agent when building" do
        expect(permission.agent.first.rdf_subject.to_s).to eq 'http://projecthydra.org/ns/auth/person#archivist1@example.com'
      end
    end
  end
end
