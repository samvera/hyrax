require 'spec_helper'

describe Hydra::AccessControls::Permissions do
  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
    end
  end

  let(:model) { Foo.new }
  subject { model }

  describe "#permisisons" do
    subject { model.permissions }
    it { is_expected.to be_kind_of Hydra::AccessControl::CollectionRelationship }
  end

  it "has a set of permissions" do
    subject.read_groups=['group1', 'group2']
    subject.edit_users=['user1']
    subject.read_users=['user2', 'user3']
    expect(subject.permissions.to_a).to all(be_kind_of(Hydra::AccessControls::Permission))
    expect(subject.permissions.map(&:to_hash)).to match_array [{type: "group", access: "read", name: "group1"},
        { type: "group", access: "read", name: "group2" },
        { type: "person", access: "read", name: "user2" },
        { type: "person", access: "read", name: "user3" },
        { type: "person", access: "edit", name: "user1" }]
  end

  describe "building a new permission" do
    before { subject.save! }

    it "sets the accessTo association" do
      perm = subject.permissions.build(name: 'user1', type: 'person', access: 'read')
      expect(perm.access_to_id).to eq subject.id
    end

    it "autosaves the permissions" do
      subject.permissions.build(name: 'user1', type: 'person', access: 'read')
      subject.save!
      subject.reload
      foo = Foo.find(subject.id)
      expect(foo.permissions.to_a).not_to eq []
    end
  end

  describe "updating permissions" do
    describe "with nested attributes" do
      let(:original_permissions) { [{ type: "person", access: "edit", name: "jcoyne" }] }
      before do
        subject.save!
        subject.permissions_attributes = original_permissions
      end

      context "with ids" do
        let(:permission_id) { ActiveFedora::Base.uri_to_id(subject.permissions.last.rdf_subject.to_s) }
        it "clears the cache" do
          expect {
            subject.permissions_attributes = [{ id: permission_id, type: "person", access: "read", name: "jcoyne" }]
          }.to change { subject.permissions.map(&:to_hash) }
            .from(original_permissions)
            .to([{ type: "person", access: "read", name: "jcoyne" }])
        end
      end

      context "when a hash is passed" do
        before do
          subject.permissions_attributes = {'0' => { type: "group", access:"read", name:"group1" },
                                            '1' => { type: 'person', access: 'edit', name: 'user2' }}
        end
        it "handles a hash" do
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions.map(&:to_hash)).to match_array [
              { type: "person", access: "edit", name: "jcoyne" },
              { type: "group", access: "read", name: "group1" },
              { type: "person", access: "edit", name: "user2" }]
        end
      end

      it "creates new group permissions" do
        subject.permissions_attributes = [{ type: "group", access: "read", name: "group1" }]
        expect(subject.permissions.size).to eq 2
        expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
        expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
        expect(subject.permissions[1].to_hash).to eq(type: "group", access: "read", name: "group1")
      end

      it "creates new user permissions" do
        subject.permissions_attributes = [{ type: "person", access: "read", name: "user1" }]
        expect(subject.permissions.size).to eq 2
        expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
        expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
        expect(subject.permissions[1].to_hash).to eq(type: "person", access: "read", name: "user1")
      end

      context "when called multiple times" do
        it "doesn't replace existing groups" do
          subject.permissions_attributes = [{ type: "group", access: "read", name: "group1" }]
          subject.permissions_attributes = [{ type: "group", access: "read", name: "group2" }]
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "group", access: "read", name: "group1")
          expect(subject.permissions[2].to_hash).to eq(type: "group", access: "read", name: "group2")
        end

        it "doesn't replace existing users" do
          subject.permissions_attributes = [{ type: "person", access: "read", name: "user1" }]
          subject.permissions_attributes = [{ type: "person", access: "read", name: "user2" }]
          expect(subject.permissions.size).to eq 3
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "person", access: "read", name: "user1")
          expect(subject.permissions[2].to_hash).to eq(type: "person", access: "read", name: "user2")
        end

        it "updates permissions on existing users" do
          subject.update permissions_attributes: [{ type: "person", access: "read", name: "user1" }]
          subject.update permissions_attributes: [{ type: "person", access: "edit", name: "user1" }]
          expect(subject.permissions.size).to eq 2
          expect(subject.permissions.to_a).to all(be_a(Hydra::AccessControls::Permission))
          expect(subject.permissions[0].to_hash).to eq(type: "person", access: "edit", name: "jcoyne")
          expect(subject.permissions[1].to_hash).to eq(type: "person", access: "edit", name: "user1")
        end

        it "updates permissions on existing groups" do
          subject.update permissions_attributes: [{ type: "group", access: "read", name: "group1" }]
          subject.update permissions_attributes: [{ type: "group", access: "edit", name: "group1" }]
          expect(subject.permissions.map(&:to_hash)).to match_array [
                                            { type: "group", access: "edit", name: "group1" },
                                            { type: "person", access: "edit", name: "jcoyne" }]
        end
      end

      context "when the destroy flag is set" do
        let(:reloaded) { subject.reload.permissions.map(&:to_hash) }
        let(:permissions_id) { ActiveFedora::Base.uri_to_id(subject.permissions.last.rdf_subject.to_s) }

        context "to a truthy value" do
          context "when updating users" do
            before do
              subject.update permissions_attributes: [{ type: "person", access: "read", name: "user1" }]
              subject.update permissions_attributes: [{ id: permissions_id, type: "person", access: "edit", name: "user1", _destroy: 'true' }]
            end

            it "removes permissions on existing users" do
              indexed_result = ActiveFedora::SolrService.query("id:#{subject.id}").first['edit_access_person_ssim']
              expect(indexed_result).to eq ['jcoyne']
              expect(subject.permissions.map(&:to_hash)).to eq [{ name: "jcoyne", type: "person", access: "edit" }]
              expect(reloaded).to eq [{ name: "jcoyne", type: "person", access: "edit" }]
            end
          end

          context "when updating groups" do
            before do
              subject.update permissions_attributes: [{ type: "group", access: "read", name: "group1" }]
              subject.update permissions_attributes: [{ id: permissions_id, type: "group", access: "edit", name: "group1", _destroy: '1' }]
            end

            it "removes permissions on existing groups" do
              #See what actually gets stored in solr
              indexed_result = ActiveFedora::SolrService.query("id:#{subject.id}").first['edit_access_group_ssim']
              expect(indexed_result).to be_nil
              expect(reloaded).to eq [{ type: "person", access: "edit", name: "jcoyne" }]
            end
          end

          context "when destroy and update are simultaneously set for the same id" do
            let(:simultaneous) do
              [
                { id: permissions_id, type: "group", access: "read", name: "group1", _destroy: '1' },
                { id: permissions_id, type: "group", access: "read", name: "group1", }
              ]
            end
            before do
              subject.update permissions_attributes: [{ type: "group", access: "read", name: "group1" }]
              subject.update permissions_attributes: simultaneous
            end

            it "leaves the permissions unchanged" do
              expect(reloaded).to contain_exactly({name: "jcoyne", type: "person", access: "edit"}, {name: "group1", type: "group", access: "read"})
            end
          end

          context "when destroy is present without an id" do
            let(:missing_id) do
              [ { type: "group", access: "read", name: "group1", _destroy: '1' } ]
            end
            before do
              subject.update permissions_attributes: missing_id
            end

            it "leaves the permissions unchanged" do
              expect(reloaded).to contain_exactly({name: "jcoyne", type: "person", access: "edit"})
            end
          end

          context "when updating multiple different permissions at the same time" do
            before do
              subject.update permissions_attributes: [{ type: "group", access: "read", name: "group1" }]
              subject.update permissions_attributes: [
                { id: permissions_id, type: "group", access: "read", name: "group1", _destroy: '1' },
                { type: "group", access: "edit", name: "group2" },
                { type: "person", access: "read", name: "joebob" }
              ]
            end

            it "removes permissions on existing groups and updates the others" do
              expect(reloaded).to contain_exactly(
                {name: "jcoyne", type: "person", access: "edit"},
                {name: "group2", type: "group",  access: "edit"},
                {name: "joebob", type: "person", access: "read"}
              )
            end
          end
        end

        context "to a falsy value" do

          it "doesn't remove the record" do
            subject.update permissions_attributes: [{ type: "group", access: "read", name: "group1" }]
            subject.update permissions_attributes: [{ id: permissions_id, type: "group", access: "edit", name: "group1", _destroy: '0' }]
            expect(reloaded).to match_array [{ type: "group", access: "edit", name: "group1" },
                                             { type: "person", access: "edit", name: "jcoyne" }]
          end
        end
      end
    end

    describe "with the setter" do
      before do
        subject.permissions = [
          Hydra::AccessControls::Permission.new(type: "group", access: "edit", name: "group1"),
          Hydra::AccessControls::Permission.new(type: "person", access: "edit", name: "jcoyne")]
        subject.save!
      end
      it "sets the permissions" do
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

    it "has read groups accessor" do
      expect(subject.read_groups).to eq ['group-6', 'group-7']
    end

    it "has read groups string accessor" do
      expect(subject.read_groups_string).to eq 'group-6, group-7'
    end

    it "has read groups string writer" do
      subject.read_groups_string = 'umg/up.dlt.staff, group-3'
      expect(subject.read_groups).to eq ['umg/up.dlt.staff', 'group-3']
      expect(subject.edit_groups).to eq ['group-8']
      expect(subject.read_users).to eq ['person1']
    end

    it "only revoke eligible groups" do
      subject.set_read_groups(['group-2', 'group-3'], ['group-6'])
      # 'group-7' is not eligible to be revoked
      expect(subject.permissions.map(&:to_hash)).to match_array([
        { name: 'group-2', type: 'group', access: 'read' },
        { name: 'group-3', type: 'group', access: 'read' },
        { name: 'group-7', type: 'group', access: 'read' },
        { name: 'group-8', type: 'group', access: 'edit' },
        { name: 'person1', type: 'person', access: 'read' },
        { name: 'person2', type: 'person', access: 'discover' }])
    end
  end

  context "when the original object is destroyed" do
    before do
      subject.save!
      subject.permissions.create(type: 'person', access: 'read', name: 'person1')
      subject.save!
    end

    it "destroys the associated permissions" do
      expect { subject.destroy }.to change { Hydra::AccessControls::Permission.count }.by(-1)
    end

    it "does not raise an exception if permissions do not exist" do
      expect { Foo.new.destroy }.not_to raise_error(NoMethodError)
    end
  end
end
