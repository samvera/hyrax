RSpec.describe Hyrax::Collections::PermissionsService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe ".can_deposit_in_collection?" do
    subject { described_class.can_deposit_in_collection?(collection: collection, user: user) }

    let(:ability) { double }

    let(:permission_template) { create(:permission_template) }
    let(:collection) { create(:collection, user: user) }

    before do
      allow(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: collection.id).and_return(permission_template)
      allow(ability).to receive(:current_user).and_return(user)
      allow(user).to receive(:ability).and_return(ability)
      allow(ability).to receive(:user_groups).and_return(['public', 'registered'])
    end

    it "exists" do
      expect(described_class).to respond_to(:can_deposit_in_collection?)
    end

    it "returns true when user is a manager" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      expect(subject).to be true
    end

    it "returns true when user is a depositor" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      expect(subject).to be true
    end

    it "returns false when user is a viewer" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      expect(subject).to be false
    end

    context "when manage group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      end

      it "returns true if user has any valid group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'managers'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_managers', 'managers', 'other_group'])
        expect(subject).to be true
      end
    end

    context "when deposit group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
      end

      it "returns true if user has any valid group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'depositors'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_depositors', 'depositors', 'other_group'])
        expect(subject).to be true
      end
    end

    context "when view group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return(['viewers', 'more_viewers'])
      end

      it "returns false if user has any view group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'viewers'])
        expect(subject).to be false
      end

      it "returns false if user has multiple view groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_viewers', 'viewers', 'other_group'])
        expect(subject).to be false
      end
    end

    it "returns false when user is neither a manager nor depositor" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
      allow(ability).to receive(:user_groups).and_return(['public', 'registered'])
      expect(subject).to be false
    end
  end

  describe ".can_view_admin_show_for_collection?" do
    subject { described_class.can_view_admin_show_for_collection?(collection: collection, user: user) }

    let(:ability) { double }
    let(:permission_template) { create(:permission_template) }
    let(:collection) { create(:collection, user: user) }

    before do
      allow(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: collection.id).and_return(permission_template)
      allow(ability).to receive(:current_user).and_return(user)
      allow(user).to receive(:ability).and_return(ability)
      allow(ability).to receive(:user_groups).and_return(['public', 'registered'])
    end

    it "exists" do
      expect(described_class).to respond_to(:can_view_admin_show_for_collection?)
    end

    it "returns true when user is a manager" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      expect(subject).to be true
    end

    it "returns true when user is a depositor" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      expect(subject).to be true
    end

    it "returns true when user is a viewer" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      expect(subject).to be true
    end

    context "when manage group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      end

      it "returns false if no user groups" do
        allow(ability).to receive(:user_groups).and_return([])
        expect(subject).to be false
      end

      it "returns true if user has any valid group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'managers'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_managers', 'managers', 'other_group'])
        expect(subject).to be true
      end
    end

    context "when deposit group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return([])
      end

      it "returns true if user has any valid group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'depositors'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_depositors', 'depositors', 'other_group'])
        expect(subject).to be true
      end
    end

    context "when view group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return(['viewers', 'more_viewers'])
      end

      it "returns true if user has any valid group" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'viewers'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'more_viewers', 'viewers', 'other_group'])
        expect(subject).to be true
      end
    end

    it "returns false when user is does not have access as manager, depositor, or viewer" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'view').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'view').and_return(['viewers', 'more_viewers'])
      allow(ability).to receive(:user_groups).and_return([])
      expect(subject).to be false
    end
  end

  context "access helper method" do
    let(:ability) { double }
    let(:user) { create(:user) }
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

      allow(ability).to receive(:current_user).and_return(user)
      allow(user).to receive(:ability).and_return(ability)
      allow(ability).to receive(:user_groups).and_return(['public', 'registered', 'view_group', 'manage_group', 'deposit_group'])
      allow(ability).to receive(:admin?).and_return(false)
    end

    describe '.admin_set_ids_for_user' do
      it 'returns ids for admin sets with view user and group' do
        expect(described_class.admin_set_ids_for_user(user: user, access: 'view')).to match_array [as_vu.id, as_vg.id]
      end
      it 'returns ids for admin sets with manage user and group' do
        expect(described_class.admin_set_ids_for_user(user: user, access: 'manage')).to match_array [as_mu.id, as_mg.id]
      end
      it 'returns ids for admin sets with deposit user and group' do
        expect(described_class.admin_set_ids_for_user(user: user, access: 'deposit')).to match_array [as_du.id, as_dg.id]
      end
    end

    describe '.collection_ids_for_user' do
      it 'returns ids for collections with view user and group' do
        expect(described_class.collection_ids_for_user(user: user, access: 'view')).to match_array [col_vu.id, col_vg.id]
      end
      it 'returns ids for collections with manage user and group' do
        expect(described_class.collection_ids_for_user(user: user, access: 'manage')).to match_array [col_mu.id, col_mg.id]
      end
      it 'returns ids for collections with deposit user and group' do
        expect(described_class.collection_ids_for_user(user: user, access: 'deposit')).to match_array [col_du.id, col_dg.id]
      end
    end

    describe '.source_ids_for_user' do
      it 'returns ids for collections with view user and group' do
        expect(described_class.source_ids_for_user(user: user, access: 'view')).to match_array [col_vu.id, col_vg.id, as_vu.id, as_vg.id]
      end
      it 'returns ids for collections with manage user and group' do
        expect(described_class.source_ids_for_user(user: user, access: 'manage')).to match_array [col_mu.id, col_mg.id, as_mu.id, as_mg.id]
      end
      it 'returns ids for collections with deposit user and group' do
        expect(described_class.source_ids_for_user(user: user, access: 'deposit')).to match_array [col_du.id, col_dg.id, as_du.id, as_dg.id]
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
