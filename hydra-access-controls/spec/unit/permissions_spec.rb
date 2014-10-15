require 'spec_helper'

describe Hydra::AccessControls::Permissions do
  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
    end
  end

  subject { Foo.new }

  it "should have many permissions" do
    expect(subject.permissions).to eq []
  end

  #TODO is permission same as an acl?

  it "should have a set of permissions" do
    subject.read_groups=['group1', 'group2']
    subject.edit_users=['user1']
    subject.read_users=['user2', 'user3']
    expect(subject.permissions).to match_array [Hydra::AccessControls::Permission.new(:type=>"group", :access=>"read", :name=>"group1"),
        Hydra::AccessControls::Permission.new({:type=>"group", :access=>"read", :name=>"group2"}),
        Hydra::AccessControls::Permission.new({:type=>"person", :access=>"read", :name=>"user2"}),
        Hydra::AccessControls::Permission.new({:type=>"person", :access=>"read", :name=>"user3"}),
        Hydra::AccessControls::Permission.new({:type=>"person", :access=>"edit", :name=>"user1"})]
  end

  describe "building a new permission" do
    before { subject.save! }

    it "should set the accessTo association" do
      perm = subject.permissions.build(name: 'user1', type: 'person', access: 'read')
      subject.save
      expect(perm.access_to_id).to eq subject.id
    end
  end

  describe "updating permissions" do
    describe "with nested attributes" do
      before do
        subject.save!
        subject.permissions_attributes = [{:type=>"person", :access=>"edit", :name=>"jcoyne"}]
      end
      context "when a hash is passed" do
        before do
          subject.permissions_attributes = {'0' => {type: "group", access:"read", name:"group1"},
                                            '1' => {type: 'person', access: 'edit', name: 'user2'}}
        end
        it "should handle a hash" do
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions.map(&:to_hash)).to match_array [
              {type: "person", access: "edit", name: "jcoyne"},
              {type: "group", access: "read", name: "group1"},
              {type: "person", access: "edit", name: "user2"}]
        end
      end

      it "should create new group permissions" do
        subject.permissions_attributes = [{type: "group", access: "read", name: "group1"}]
        expect(subject.permissions.size).to eq 2
        expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
        expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
        expect(subject.permissions[1].to_hash).to eq(type: "group", access: "read", name: "group1")
      end

      it "should create new user permissions" do
        subject.permissions_attributes = [{:type=>"person", :access=>"read", :name=>"user1"}]
        expect(subject.permissions.size).to eq 2
        expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
        expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
        expect(subject.permissions[1].to_hash).to eq(type: "person", access: "read", name: "user1")
      end

      context "when called multiple times" do
        it "should not replace existing groups" do
          subject.permissions_attributes = [{:type=>"group", :access=>"read", :name=>"group1"}]
          subject.permissions_attributes = [{:type=>"group", :access=>"read", :name=>"group2"}]
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "group", access: "read", name: "group1")
          expect(subject.permissions[2].to_hash).to eq(type: "group", access: "read", name: "group2")
        end

        it "should not replace existing users" do
          subject.permissions_attributes = [{:type=>"person", :access=>"read", :name=>"user1"}]
          subject.permissions_attributes = [{:type=>"person", :access=>"read", :name=>"user2"}]
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "person", access: "read", name: "user1")
          expect(subject.permissions[2].to_hash).to eq(type: "person", access: "read", name: "user2")
        end

        it "should update permissions on existing users" do
          subject.update permissions_attributes: [{:type=>"person", :access=>"read", :name=>"user1"}]
          subject.update permissions_attributes: [{:type=>"person", :access=>"edit", :name=>"user1"}]
          expect(subject.permissions.size).to eq 2
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "person", access: "edit", name: "user1")
        end

        it "should update permissions on existing groups" do
          subject.update permissions_attributes: [{:type=>"group", :access=>"read", :name=>"group1"}]
          subject.update permissions_attributes: [{:type=>"group", :access=>"edit", :name=>"group1"}]
          expect(subject.permissions.map(&:to_hash)).to match_array [
                                            {:type=>"group", :access=>"edit", :name=>"group1"},
                                            {:type=>"person", :access=>"edit", :name=>"jcoyne"}]
        end
      end

      it "should remove permissions on existing users" do
        subject.update permissions_attributes: [{:type=>"person", :access=>"read", :name=>"user1"}]
        subject.update permissions_attributes: [{:id=>ActiveFedora::Base.uri_to_id(subject.permissions.last.rdf_subject.to_s), :type=>"person", :access=>"edit", :name=>"user1", _destroy: true}]
        expect(subject.permissions.reload.map(&:to_hash)).to eq [{ :name=>"jcoyne", :type=>"person", :access=>"edit" }]
      end

      it "should remove permissions on existing groups" do
        subject.update permissions_attributes: [{:type=>"group", :access=>"read", :name=>"group1"}]
        subject.update permissions_attributes: [{:id=>ActiveFedora::Base.uri_to_id(subject.permissions.last.rdf_subject.to_s), :type=>"group", :access=>"edit", :name=>"group1", _destroy: '1'}]
        expect(subject.permissions.reload.map(&:to_hash)).to eq [{:type=>"person", :access=>"edit", :name=>"jcoyne"}]
      end

      it "should not remove when destroy flag is falsy" do
        subject.update permissions_attributes: [{:type=>"group", :access=>"read", :name=>"group1"}]
        subject.update permissions_attributes: [{:id=>ActiveFedora::Base.uri_to_id(subject.permissions.last.rdf_subject.to_s), :type=>"group", :access=>"edit", :name=>"group1", _destroy: '0'}]
        expect(subject.permissions.reload.map(&:to_hash)).to match_array [{:type=>"group", :access=>"edit", :name=>"group1"},
                                                          {:type=>"person", :access=>"edit", :name=>"jcoyne"}]
      end
    end

    describe "with the setter" do
      before do
        subject.permissions = [
          Hydra::AccessControls::Permission.new(:type=>"group", :access=>"edit", :name=>"group1"),
          Hydra::AccessControls::Permission.new(:type=>"person", :access=>"edit", :name=>"jcoyne")]
        subject.save!
      end
      it "should set the permissions" do
        expect(subject.edit_users).to eq ['jcoyne']
        expect(subject.edit_groups).to eq ['group1']
        subject.permissions = []
        expect(subject.edit_users).to be_empty
        expect(subject.edit_groups).to be_empty
      end

    end
  end
  context "with rightsMetadata" do
    before do
      subject.permissions.build(type: 'person', access: 'read', name: 'person1')
      subject.permissions.build(type: 'person', access: 'discover', name: 'person2')
      subject.permissions.build(type: 'group', access: 'read', name: 'group-6')
      subject.permissions.build(type: 'group', access: 'read', name: 'group-7')
      subject.permissions.build(type: 'group', access: 'edit', name: 'group-8')
    end

    it "should have read groups accessor" do
      expect(subject.read_groups).to eq ['group-6', 'group-7']
    end

    it "should have read groups string accessor" do
      expect(subject.read_groups_string).to eq 'group-6, group-7'
    end

    it "should have read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      expect(subject.read_groups).to eq ['umg/up.dlt.staff', 'group-3']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to eq ['person1']
    end

    it "should only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.permissions.map(&:to_hash)).to match_array([
        {name: 'group-2', type: 'group', access: 'read'},
        {name: 'group-3', type: 'group', access: 'read'},
        {name: 'group-7', type: 'group', access: 'read'},
        {name: 'group-8', type: 'group', access: 'edit'},
        {name: 'person1', type: 'person', access: 'read'},
        {name: 'person2', type: 'person', access: 'discover'}])
    end
  end
end
