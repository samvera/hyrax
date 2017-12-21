RSpec.describe Hyrax::Collections::MigrationService, clean_repo: true do
  let(:user) { create(:user) }
  let(:editor1) { create(:user) }
  let(:editor2) { create(:user) }
  let(:reader1) { create(:user) }
  let(:reader2) { create(:user) }
  let(:default_gid) { create(:user_collection_type).gid }

  describe ".migrate_all_collections" do
    context 'when legacy collections are found (e.g. collections created before Hyrax 2.1.0)' do
      let!(:col_none) { build(:typeless_collection, id: 'col_none', user: user, edit_users: [user.user_key], do_save: true) }
      let!(:col_vu) { build(:typeless_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key], do_save: true) }
      let!(:col_vg) { build(:typeless_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'], do_save: true) }
      let!(:col_mu) { build(:typeless_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key], do_save: true) }
      let!(:col_mg) { build(:typeless_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'], do_save: true) }

      it 'sets gid and adds permissions' do # rubocop:disable RSpec/ExampleLength
        Collection.all.each do |col|
          expect(col.collection_type_gid).to be_nil
          expect { Hyrax::PermissionTemplate.find_by!(source_id: col.id) }.to raise_error ActiveRecord::RecordNotFound
        end

        Hyrax::Collections::MigrationService.migrate_all_collections

        Collection.all.each do |col|
          expect(col.collection_type_gid).to eq default_gid
          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
          expect(pt_id).not_to be_nil
          expect_access(pt_id, 'user', :manage, col.edit_users)
          expect_access(pt_id, 'group', :manage, col.edit_groups)
          expect_access(pt_id, 'user', :view, col.read_users)
          expect_access(pt_id, 'group', :view, col.read_groups)
        end
      end
    end

    context 'when newer collections are found (e.g. collections created at or after Hyrax 2.1.0)' do
      let!(:collection) do
        create(:collection, id: 'col_newer', user: user, with_permission_template: true,
                            collection_type_settings: [:discoverable], edit_users: [user.user_key],
                            create_access: true)
      end
      let!(:permission_template) { collection.permission_template }
      let!(:collection_type_gid) { collection.collection_type_gid }
      let!(:edit_users) { collection.edit_users }

      it "doesn't change the collection" do
        expect(collection.collection_type_gid).to eq collection_type_gid
        expect(Hyrax::PermissionTemplate.find_by!(source_id: collection.id).id).to eq permission_template.id
        expect_access(permission_template.id, 'user', :manage, edit_users)

        Hyrax::Collections::MigrationService.migrate_all_collections

        expect(collection.collection_type_gid).to eq collection_type_gid
        expect(Hyrax::PermissionTemplate.find_by!(source_id: collection.id).id).to eq permission_template.id
        expect_access(permission_template.id, 'user', :manage, edit_users)
      end
    end
  end

  describe ".repair_migrated_collections" do
    context 'when legacy collections are found (e.g. collections created before Hyrax 2.1.0)' do
      let!(:col_none) { build(:typeless_collection, id: 'col_none', user: user, edit_users: [user.user_key], do_save: true) }
      let!(:col_vu) { build(:typeless_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key], do_save: true) }
      let!(:col_vg) { build(:typeless_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'], do_save: true) }
      let!(:col_mu) { build(:typeless_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key], do_save: true) }
      let!(:col_mg) { build(:typeless_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'], do_save: true) }

      context "and collection wasn't migrated at all" do
        let!(:col_none) { build(:typeless_collection, id: 'col_none', user: user, edit_users: [user.user_key], do_save: true) }
        let!(:col_vu) { build(:typeless_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key], do_save: true) }
        let!(:col_vg) { build(:typeless_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'], do_save: true) }
        let!(:col_mu) { build(:typeless_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key], do_save: true) }
        let!(:col_mg) { build(:typeless_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'], do_save: true) }

        it 'sets gid and adds permissions' do # rubocop:disable RSpec/ExampleLength
          Collection.all.each do |col|
            expect(col.collection_type_gid).to be_nil
            expect { Hyrax::PermissionTemplate.find_by!(source_id: col.id) }.to raise_error ActiveRecord::RecordNotFound
          end

          Hyrax::Collections::MigrationService.repair_migrated_collections

          Collection.all.each do |col|
            expect(col.collection_type_gid).to eq default_gid
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_access(pt_id, 'user', :manage, col.edit_users)
            expect_access(pt_id, 'group', :manage, col.edit_groups)
            expect_access(pt_id, 'user', :view, col.read_users)
            expect_access(pt_id, 'group', :view, col.read_groups)
          end
        end
      end

      context "and collection type gid is set but permission template doesn't exist" do
        let!(:col_none) { create(:user_collection, id: 'col_none', user: user, edit_users: [user.user_key], collection_type_gid: default_gid) }
        let!(:col_vu) { create(:user_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key], collection_type_gid: default_gid) }
        let!(:col_vg) { create(:user_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'], collection_type_gid: default_gid) }
        let!(:col_mu) { create(:user_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key], collection_type_gid: default_gid) }
        let!(:col_mg) { create(:user_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'], collection_type_gid: default_gid) }

        it 'sets gid and adds permissions' do # rubocop:disable RSpec/ExampleLength
          Collection.all.each do |col|
            expect(col.collection_type_gid).to eq default_gid
            expect { Hyrax::PermissionTemplate.find_by!(source_id: col.id) }.to raise_error ActiveRecord::RecordNotFound
          end

          Hyrax::Collections::MigrationService.repair_migrated_collections

          Collection.all.each do |col|
            expect(col.collection_type_gid).to eq default_gid
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_access(pt_id, 'user', :manage, col.edit_users)
            expect_access(pt_id, 'group', :manage, col.edit_groups)
            expect_access(pt_id, 'user', :view, col.read_users)
            expect_access(pt_id, 'group', :view, col.read_groups)
          end
        end
      end

      context "and collection type gid isn't set but permission template exists with access set" do
        let!(:col_none) { build(:typeless_collection, id: 'col_none', user: user, edit_users: [user.user_key], do_save: true, with_permission_template: true) }
        let!(:col_vu) do
          build(:typeless_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_vg) do
          build(:typeless_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_mu) do
          build(:typeless_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_mg) do
          build(:typeless_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'],
                                      do_save: true, with_permission_template: true)
        end

        before do
          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col_none.id)
          create_access(pt_id, 'user', :manage, [user.user_key])

          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col_vu.id)
          create_access(pt_id, 'user', :manage, [user.user_key])
          create_access(pt_id, 'user', :view, col_vu.read_users)

          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col_vg.id)
          create_access(pt_id, 'user', :manage, [user.user_key])
          create_access(pt_id, 'group', :view, col_vg.read_groups)

          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col_mu.id)
          create_access(pt_id, 'user', :manage, col_mu.edit_users)

          pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col_mg.id)
          create_access(pt_id, 'user', :manage, [user.user_key])
          create_access(pt_id, 'group', :manage, col_mg.edit_groups)
        end

        it 'sets gid' do # rubocop:disable RSpec/ExampleLength
          Collection.all.each do |col|
            expect(col.collection_type_gid).to be_nil
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_access(pt_id, 'user', :manage, col.edit_users)
            expect_access(pt_id, 'group', :manage, col.edit_groups)
            expect_access(pt_id, 'user', :view, col.read_users)
            expect_access(pt_id, 'group', :view, col.read_groups)
          end

          Hyrax::Collections::MigrationService.repair_migrated_collections

          Collection.all.each do |col|
            expect(col.collection_type_gid).to eq default_gid
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_access(pt_id, 'user', :manage, col.edit_users)
            expect_access(pt_id, 'group', :manage, col.edit_groups)
            expect_access(pt_id, 'user', :view, col.read_users)
            expect_access(pt_id, 'group', :view, col.read_groups)
          end
        end
      end

      context "and collection type gid isn't set and permission template exists with access not set" do
        let!(:col_none) { build(:typeless_collection, id: 'col_none', user: user, edit_users: [user.user_key], do_save: true, with_permission_template: true) }
        let!(:col_vu) do
          build(:typeless_collection, id: 'col_vu', user: user, edit_users: [user.user_key], read_users: [reader1.user_key, reader2.user_key],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_vg) do
          build(:typeless_collection, id: 'col_vg', user: user, edit_users: [user.user_key], read_groups: ['read_group1', 'read_group_2'],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_mu) do
          build(:typeless_collection, id: 'col_mu', user: user, edit_users: [user.user_key, editor1.user_key, editor2.user_key],
                                      do_save: true, with_permission_template: true)
        end
        let!(:col_mg) do
          build(:typeless_collection, id: 'col_mg', user: user, edit_users: [user.user_key], edit_groups: ['edit_group1', 'edit_group_2'],
                                      do_save: true, with_permission_template: true)
        end

        it 'sets gid and adds access permissions' do # rubocop:disable RSpec/ExampleLength
          Collection.all.each do |col|
            expect(col.collection_type_gid).to be_nil
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_no_access(pt_id, 'user', :manage, col.edit_users)
            expect_no_access(pt_id, 'group', :manage, col.edit_groups)
            expect_no_access(pt_id, 'user', :view, col.read_users)
            expect_no_access(pt_id, 'group', :view, col.read_groups)
          end

          Hyrax::Collections::MigrationService.repair_migrated_collections

          Collection.all.each do |col|
            expect(col.collection_type_gid).to eq default_gid
            pt_id = Hyrax::PermissionTemplate.find_by!(source_id: col.id)
            expect(pt_id).not_to be_nil
            expect_access(pt_id, 'user', :manage, col.edit_users)
            expect_access(pt_id, 'group', :manage, col.edit_groups)
            expect_access(pt_id, 'user', :view, col.read_users)
            expect_access(pt_id, 'group', :view, col.read_groups)
          end
        end
      end
    end

    context 'when newer collections are found (e.g. collections created at or after Hyrax 2.1.0)' do
      let!(:collection) do
        create(:collection, id: 'col_newer', user: user, with_permission_template: true, collection_type_settings: [:discoverable],
                            edit_users: [user.user_key], create_access: true)
      end
      let!(:permission_template) { collection.permission_template }
      let!(:collection_type_gid) { collection.collection_type_gid }
      let!(:edit_users) { collection.edit_users }

      it "doesn't change the collection" do
        expect(collection.collection_type_gid).to eq collection_type_gid
        expect(Hyrax::PermissionTemplate.find_by!(source_id: collection.id).id).to eq permission_template.id
        expect_access(permission_template.id, 'user', :manage, edit_users)

        Hyrax::Collections::MigrationService.repair_migrated_collections

        expect(collection.collection_type_gid).to eq collection_type_gid
        expect(Hyrax::PermissionTemplate.find_by!(source_id: collection.id).id).to eq permission_template.id
        expect_access(permission_template.id, 'user', :manage, edit_users)
      end
    end
  end

  def create_access(permission_template_id, agent_type, access, agent_ids)
    agent_ids.each do |agent_id|
      create(:permission_template_access,
             access,
             permission_template: permission_template_id,
             agent_type: agent_type,
             agent_id: agent_id)
    end
  end

  def expect_access(permission_template_id, agent_type, access, agent_ids)
    agent_ids.each do |agent_id|
      pta = Hyrax::PermissionTemplateAccess.where(permission_template_id: permission_template_id, agent_type: agent_type,
                                                  access: access, agent_id: agent_id)
      expect(pta).not_to be_empty
    end
  end

  def expect_no_access(permission_template_id, agent_type, access, agent_ids)
    agent_ids.each do |agent_id|
      pta = Hyrax::PermissionTemplateAccess.where(permission_template_id: permission_template_id, agent_type: agent_type,
                                                  access: access, agent_id: agent_id)
      expect(pta).to be_empty
    end
  end
end
