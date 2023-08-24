# frozen_string_literal: true
RSpec.describe InheritPermissionsJob do
  let(:user) { FactoryBot.create(:user) }

  context "when using a legacy AF resource", :active_fedora do
    let(:work) { FactoryBot.create(:work_with_one_file, user: user) }

    before do
      work.permissions.build(name: name, type: type, access: access)
      work.save
    end

    context "when edit people change" do
      let(:name) { 'abc@123.com' }
      let(:type) { 'person' }
      let(:access) { 'edit' }

      it 'copies permissions to its contained files' do
        # files have the depositor as the edit user to begin with
        expect(work.file_sets.first.edit_users).to eq [user.to_s]

        described_class.perform_now(work)

        file_sets = work.reload.file_sets
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s, "abc@123.com"]
      end

      context "when people should be removed" do
        before do
          file_set = work.file_sets.first
          file_set.permissions.build(name: "remove_me", type: type, access: access)
          file_set.save
        end

        it 'copies permissions to its contained files' do
          # files have the depositor as the edit user to begin with
          expect(work.file_sets.first.edit_users).to eq [user.to_s, "remove_me"]

          described_class.perform_now(work)

          file_sets = work.reload.file_sets
          expect(file_sets.count).to eq 1
          expect(file_sets[0].edit_users).to match_array [user.to_s, "abc@123.com"]
        end
      end
    end

    context "when read people change" do
      let(:name) { 'abc@123.com' }
      let(:type) { 'person' }
      let(:access) { 'read' }

      it 'copies permissions to its contained files' do
        # files have no read users to begin with
        expect(work.file_sets.first.read_users).to eq []

        described_class.perform_now(work)

        file_sets = work.reload.file_sets
        expect(file_sets.count).to eq 1
        expect(file_sets[0].read_users).to match_array ["abc@123.com"]
        expect(file_sets[0].edit_users).to match_array [user.to_s]
      end
    end

    context "when read groups change" do
      let(:name) { 'my_read_group' }
      let(:type) { 'group' }
      let(:access) { 'read' }

      it 'copies permissions to its contained files' do
        # files have no read groups to begin with
        expect(work.file_sets.first.read_groups).to eq []

        described_class.perform_now(work)

        file_sets = work.reload.file_sets
        expect(file_sets.count).to eq 1
        expect(file_sets[0].read_groups).to match_array ["my_read_group"]
        expect(file_sets[0].edit_users).to match_array [user.to_s]
      end
    end

    context "when edit groups change" do
      let(:name) { 'my_edit_group' }
      let(:type) { 'group' }
      let(:access) { 'edit' }

      it 'copies permissions to its contained files' do
        # files have the depositor as the edit user to begin with
        expect(work.file_sets.first.read_groups).to eq []

        described_class.perform_now(work)

        file_sets = work.reload.file_sets
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_groups).to match_array ["my_edit_group"]
        expect(file_sets[0].edit_users).to match_array [user.to_s]
      end
    end
  end

  context "when passed a valkyrie model", valkyrie_adapter: :test_adapter do
    let(:resource) { FactoryBot.valkyrie_create(:hyrax_work, edit_users: [user]) }
    let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
    let(:user2) { FactoryBot.create(:user) }

    before do
      resource.member_ids = Array(file_set.id)
      file_set.permission_manager.acl.grant(:edit).to(user).save
    end

    context "when edit people change" do
      it 'copies permissions to its contained files' do
        resource.permission_manager.acl.grant(:edit).to(user2).save
        expect(resource.edit_users).to match_array [user.to_s, user2.to_s]

        # files have the depositor as the edit user to begin with
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s]

        described_class.perform_now(resource)

        # files have both edit users from parent resource
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s, user2.to_s]
      end
    end

    context "when people should be removed" do
      it 'copies permissions to its contained files' do
        file_set.permission_manager.acl.grant(:edit).to(user2).save
        # work has the depositor as the edit user to begin with
        expect(resource.edit_users).to match_array [user.to_s]

        # files have the depositor and extra user as the edit users to begin with
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s, user2.to_s]

        described_class.perform_now(resource)

        # files have single edit user from parent resource
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s]
      end
    end

    context "when read people change" do
      it 'copies permissions to its contained files' do
        resource.permission_manager.acl.grant(:read).to(user2).save
        expect(resource.read_users).to match_array [user2.to_s]

        # files have no read users to begin with
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].read_users.to_a).to be_empty

        described_class.perform_now(resource)

        # files have the specified read user
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].read_users.to_a).to match_array [user2.to_s]
      end
    end

    context "when read groups change" do
      let(:group) { Hyrax::Group.new('my_read_group') }

      it 'copies permissions to its contained files' do
        resource.permission_manager.acl.grant(:read).to(group).save

        # work has the specified read group to begin with
        expect(resource.read_groups).to match_array ["my_read_group"]

        described_class.perform_now(resource)

        # files have the specified read group
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s]
        expect(file_sets[0].read_groups).to match_array ["my_read_group"]
      end
    end

    context "when edit groups change" do
      let(:group) { Hyrax::Group.new('my_edit_group') }

      it 'copies permissions to its contained files' do
        resource.permission_manager.acl.grant(:edit).to(group).save

        # work has the specified edit group to begin with
        expect(resource.edit_groups).to match_array ["my_edit_group"]

        described_class.perform_now(resource)

        # files have the specified edit group
        file_sets = Hyrax.query_service.custom_queries.find_child_file_sets(resource: resource)
        expect(file_sets.count).to eq 1
        expect(file_sets[0].edit_users).to match_array [user.to_s]
        expect(file_sets[0].edit_groups).to match_array ["my_edit_group"]
      end
    end
  end
end
