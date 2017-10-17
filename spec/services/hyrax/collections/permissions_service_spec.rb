RSpec.describe Hyrax::Collections::PermissionsService do
  let(:user) { create(:user) }

  let(:ability) { double }

  context 'collection specific methods' do
    let(:collection) { create(:collection) }
    let(:admin_set) { create(:admin_set) }
    let(:col_permission_template) { create(:permission_template, source_type: 'collection', source_id: collection.id) }
    let(:as_permission_template) { create(:permission_template, source_type: 'admin_set', source_id: admin_set.id) }

    before do
      allow(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: collection.id).and_return(col_permission_template)
      allow(ability).to receive(:current_user).and_return(user)
      allow(ability).to receive(:user_groups).and_return(['public', 'registered'])
      allow(described_class).to receive(:user_admin?).with(user, nil).and_return(false)
      allow(user).to receive(:ability).and_return(ability)
    end

    context 'when manage user' do
      before do
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user.user_key])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      end

      subject { described_class }

      it ".can_deposit_in_collection? returns true" do
        expect(subject.can_deposit_in_collection?(collection_id: collection.id, user: user)).to be true
      end
      it ".can_view_admin_show_for_collection? returns true" do
        expect(subject.can_view_admin_show_for_collection?(collection_id: collection.id, user: user)).to be true
      end
    end

    context 'when deposit user' do
      before do
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user.user_key])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      end

      subject { described_class }

      it ".can_deposit_in_collection? returns true" do
        expect(subject.can_deposit_in_collection?(collection_id: collection.id, user: user)).to be true
      end
      it ".can_view_admin_show_for_collection? returns true" do
        expect(subject.can_view_admin_show_for_collection?(collection_id: collection.id, user: user)).to be true
      end
    end

    context 'when view user' do
      before do
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([user.user_key])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(col_permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      end

      subject { described_class }

      it ".can_deposit_in_collection? returns true" do
        expect(subject.can_deposit_in_collection?(collection_id: collection.id, user: user)).to be false
      end
      it ".can_view_admin_show_for_collection? returns true" do
        expect(subject.can_view_admin_show_for_collection?(collection_id: collection.id, user: user)).to be true
      end
    end

    context 'when user without access' do
      subject { described_class }

      it ".can_deposit_in_collection? returns true" do
        expect(subject.can_deposit_in_collection?(collection_id: collection.id, user: user)).to be false
      end
      it ".can_view_admin_show_for_collection? returns true" do
        expect(subject.can_view_admin_show_for_collection?(collection_id: collection.id, user: user)).to be false
      end
    end
  end

  context 'methods returning ids' do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    let(:col_vu) { create(:collection, id: 'col_vu', with_permission_template: true) }
    let(:col_vg) { create(:collection, id: 'col_vg', with_permission_template: true) }
    let(:col_mu) { create(:collection, id: 'col_mu', with_permission_template: true) }
    let(:col_mg) { create(:collection, id: 'col_mg', with_permission_template: true) }
    let(:col_du) { create(:collection, id: 'col_du', with_permission_template: true) }
    let(:col_dg) { create(:collection, id: 'col_dg', with_permission_template: true) }

    let(:as_vu) { create(:admin_set, id: 'as_vu', with_permission_template: true) }
    let(:as_vg) { create(:admin_set, id: 'as_vg', with_permission_template: true) }
    let(:as_mu) { create(:admin_set, id: 'as_mu', with_permission_template: true) }
    let(:as_mg) { create(:admin_set, id: 'as_mg', with_permission_template: true) }
    let(:as_du) { create(:admin_set, id: 'as_du', with_permission_template: true) }
    let(:as_dg) { create(:admin_set, id: 'as_dg', with_permission_template: true) }

    before do
      source_access(col_vu.permission_template, 'user', user.user_key, :view)
      source_access(col_vg.permission_template, 'group', 'view_group', :view)
      source_access(col_mu.permission_template, 'user', user.user_key, :manage)
      source_access(col_mg.permission_template, 'group', 'manage_group', :manage)
      source_access(col_du.permission_template, 'user', user.user_key, :deposit)
      source_access(col_dg.permission_template, 'group', 'deposit_group', :deposit)

      source_access(as_vu.permission_template, 'user', user.user_key, :view)
      source_access(as_vg.permission_template, 'group', 'view_group', :view)
      source_access(as_mu.permission_template, 'user', user.user_key, :manage)
      source_access(as_mg.permission_template, 'group', 'manage_group', :manage)
      source_access(as_du.permission_template, 'user', user.user_key, :deposit)
      source_access(as_dg.permission_template, 'group', 'deposit_group', :deposit)

      allow(user).to receive(:groups).and_return(['view_group', 'deposit_group', 'manage_group'])
    end

    describe '.source_ids_for_user' do
      it 'returns collection and admin set ids where user has manage access' do
        expect(described_class.source_ids_for_user(access: 'manage', user: user)).to match_array [col_mu.id, col_mg.id, as_mu.id, as_mg.id]
      end
      it 'returns collection ids where user has manage access' do
        expect(described_class.source_ids_for_user(access: 'manage', user: user, source_type: 'collection')).to match_array [col_mu.id, col_mg.id]
      end
      it 'returns admin set ids where user has manage access' do
        expect(described_class.source_ids_for_user(access: 'manage', user: user, source_type: 'admin_set')).to match_array [as_mu.id, as_mg.id]
      end
      it 'returns collection and admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_user(access: 'deposit', user: user)).to match_array [col_du.id, col_dg.id, as_du.id, as_dg.id]
      end
      it 'returns collection ids where user has deposit access' do
        expect(described_class.source_ids_for_user(access: 'deposit', user: user, source_type: 'collection')).to match_array [col_du.id, col_dg.id]
      end
      it 'returns admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_user(access: 'deposit', user: user, source_type: 'admin_set')).to match_array [as_du.id, as_dg.id]
      end
      it 'returns collection and admin set ids where user has view access' do
        expect(described_class.source_ids_for_user(access: 'view', user: user)).to match_array [col_vu.id, col_vg.id, as_vu.id, as_vg.id]
      end
      it 'returns collection ids where user has view access' do
        expect(described_class.source_ids_for_user(access: 'view', user: user, source_type: 'collection')).to match_array [col_vu.id, col_vg.id]
      end
      it 'returns admin set ids where user has view access' do
        expect(described_class.source_ids_for_user(access: 'view', user: user, source_type: 'admin_set')).to match_array [as_vu.id, as_vg.id]
      end
      it 'returns collection and admin set ids where user has manage, deposit, or view access' do
        all = [col_mu.id, col_mg.id, col_du.id, col_dg.id, col_vu.id, col_vg.id, as_mu.id, as_mg.id, as_du.id, as_dg.id, as_vu.id, as_vg.id]
        expect(described_class.source_ids_for_user(access: ['manage', 'deposit', 'view'], user: user)).to match_array all
      end
      it 'returns collection ids where user has manage, deposit, or view access' do
        all = [col_mu.id, col_mg.id, col_du.id, col_dg.id, col_vu.id, col_vg.id]
        expect(described_class.source_ids_for_user(access: ['manage', 'deposit', 'view'], user: user, source_type: 'collection')).to match_array all
      end
      it 'returns admin set ids where user has manage, deposit, or view access' do
        all = [as_mu.id, as_mg.id, as_du.id, as_dg.id, as_vu.id, as_vg.id]
        expect(described_class.source_ids_for_user(access: ['manage', 'deposit', 'view'], user: user, source_type: 'admin_set')).to match_array all
      end
      it 'returns empty array when user has no access' do
        expect(described_class.source_ids_for_user(access: ['manage', 'deposit', 'view'], user: user2)).to match_array []
      end
    end
    describe '.admin_set_ids_for_user' do
      it 'returns admin set ids where user has manage access' do
        expect(described_class.admin_set_ids_for_user(access: 'manage', user: user)).to match_array [as_mu.id, as_mg.id]
      end
      it 'returns admin set ids where user has deposit access' do
        expect(described_class.admin_set_ids_for_user(access: 'deposit', user: user)).to match_array [as_du.id, as_dg.id]
      end
      it 'returns admin set ids where user has view access' do
        expect(described_class.admin_set_ids_for_user(access: 'view', user: user)).to match_array [as_vu.id, as_vg.id]
      end
      it 'returns admin set ids where user has manage, deposit, or view access' do
        all = [as_mu.id, as_mg.id, as_du.id, as_dg.id, as_vu.id, as_vg.id]
        expect(described_class.admin_set_ids_for_user(access: ['manage', 'deposit', 'view'], user: user)).to match_array all
      end
      it 'returns empty array when user has no access' do
        expect(described_class.admin_set_ids_for_user(access: ['manage', 'deposit', 'view'], user: user2)).to match_array []
      end
    end
    describe '.collection_ids_for_user' do
      it 'returns collection ids where user has manage access' do
        expect(described_class.collection_ids_for_user(access: 'manage', user: user)).to match_array [col_mu.id, col_mg.id]
      end
      it 'returns collection ids where user has deposit access' do
        expect(described_class.collection_ids_for_user(access: 'deposit', user: user)).to match_array [col_du.id, col_dg.id]
      end
      it 'returns collection ids where user has view access' do
        expect(described_class.collection_ids_for_user(access: 'view', user: user)).to match_array [col_vu.id, col_vg.id]
      end
      it 'returns collection ids where user has manage, deposit, or view access' do
        all = [col_mu.id, col_mg.id, col_du.id, col_dg.id, col_vu.id, col_vg.id]
        expect(described_class.collection_ids_for_user(access: ['manage', 'deposit', 'view'], user: user)).to match_array all
      end
      it 'returns empty array when user has no access' do
        expect(described_class.collection_ids_for_user(access: ['manage', 'deposit', 'view'], user: user2)).to match_array []
      end
    end

    describe '.source_ids_for_manage' do
      it 'returns collection and admin set ids where user has manage access' do
        expect(described_class.source_ids_for_manage(user: user)).to match_array [col_mu.id, col_mg.id, as_mu.id, as_mg.id]
      end
      it 'returns collection ids where user has manage access' do
        expect(described_class.source_ids_for_manage(user: user, source_type: 'collection')).to match_array [col_mu.id, col_mg.id]
      end
      it 'returns admin set ids where user has manage access' do
        expect(described_class.source_ids_for_manage(user: user, source_type: 'admin_set')).to match_array [as_mu.id, as_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.source_ids_for_manage(user: user2)).to match_array []
      end
    end
    describe '.admin_set_ids_for_manage' do
      it 'returns admin set ids where user has manage access' do
        expect(described_class.admin_set_ids_for_manage(user: user)).to match_array [as_mu.id, as_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.admin_set_ids_for_manage(user: user2)).to match_array []
      end
    end
    describe '.collection_ids_for_manage' do
      it 'returns collection ids where user has manage access' do
        expect(described_class.collection_ids_for_manage(user: user)).to match_array [col_mu.id, col_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.collection_ids_for_manage(user: user2)).to match_array []
      end
    end

    describe '.source_ids_for_deposit' do
      it 'returns collection and admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(user: user)).to match_array [col_du.id, col_dg.id, col_mu.id, col_mg.id, as_du.id, as_dg.id, as_mu.id, as_mg.id]
      end
      it 'returns collection ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(user: user, source_type: 'collection')).to match_array [col_du.id, col_dg.id, col_mu.id, col_mg.id]
      end
      it 'returns admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(user: user, source_type: 'admin_set')).to match_array [as_du.id, as_dg.id, as_mu.id, as_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.source_ids_for_deposit(user: user2)).to match_array []
      end
    end
    describe '.collection_ids_for_deposit' do
      it 'returns collection ids where user has manage access' do
        expect(described_class.collection_ids_for_deposit(user: user)).to match_array [col_du.id, col_dg.id, col_mu.id, col_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.collection_ids_for_deposit(user: user2)).to match_array []
      end
    end
    describe '.admin_set_ids_for_deposit' do
      it 'returns admin set ids where user has manage access' do
        expect(described_class.admin_set_ids_for_deposit(user: user)).to match_array [as_du.id, as_dg.id, as_mu.id, as_mg.id]
      end
      it 'returns empty array when user has no access' do
        expect(described_class.admin_set_ids_for_deposit(user: user2)).to match_array []
      end
    end

    describe '.can_manage_any_collection?' do
      it 'returns true when user has manage access to at least one collection' do
        expect(described_class.can_manage_any_collection?(user: user)).to be true
      end
      it 'returns false when user does not have manage access to any collections' do
        expect(described_class.can_manage_any_collection?(user: user2)).to be false
      end
    end

    describe '.can_manage_any_admin_set?' do
      it 'returns true when user has manage access to at least one admin set' do
        expect(described_class.can_manage_any_admin_set?(user: user)).to be true
      end
      it 'returns false when user does not have manage access to any admin sets' do
        expect(described_class.can_manage_any_admin_set?(user: user2)).to be false
      end
    end

    describe '.can_view_admin_show_for_any_collection?' do
      it 'returns true when user has manage, deposit, or view access to at least one collection' do
        expect(described_class.can_view_admin_show_for_any_collection?(user: user)).to be true
      end
      it 'returns false when user does not have manage, deposit, or view access to any collections' do
        expect(described_class.can_view_admin_show_for_any_collection?(user: user2)).to be false
      end
    end

    describe '.can_view_admin_show_for_any_admin set?' do
      it 'returns true when user has manage, deposit, or view access to at least one admin set' do
        expect(described_class.can_view_admin_show_for_any_admin_set?(user: user)).to be true
      end
      it 'returns false when user does not have manage, deposit, or view access to any admin sets' do
        expect(described_class.can_view_admin_show_for_any_admin_set?(user: user2)).to be false
      end
    end
  end

  def source_access(permission_template, agent_type, agent_id, access)
    create(:permission_template_access,
           access,
           permission_template: permission_template,
           agent_type: agent_type,
           agent_id: agent_id)
  end
end
