# frozen_string_literal: true

RSpec.describe Hyrax::PermissionManager do
  subject(:manager)  { described_class.new(resource: resource) }
  let(:custom_group) { 'my_group_id' }
  let(:other_user)   { create(:user).user_key.to_s }
  let(:public_group) { 'public' }
  let(:resource)     { valkyrie_create(:hyrax_resource) }
  let(:user)         { create(:user).user_key.to_s }

  shared_context 'with discover groups and users' do
    before do
      manager.discover_groups = [public_group, custom_group]
      manager.discover_users  = [user, other_user]
    end
  end

  shared_context 'with edit groups and users' do
    before do
      manager.edit_groups = [public_group, custom_group]
      manager.edit_users  = [user, other_user]
    end
  end

  shared_context 'with read groups and users' do
    before do
      manager.read_groups = [public_group, custom_group]
      manager.read_users  = [user, other_user]
    end
  end

  describe '#discover_groups' do
    it 'returns the empty for no discover groups' do
      expect(manager.edit_groups.to_a).to be_empty
    end

    context 'with discover groups and users' do
      include_context 'with discover groups and users'

      it 'gives all of and only the discover groups' do
        expect(manager.discover_groups)
          .to contain_exactly(public_group, custom_group)
      end
    end
  end

  describe '#discover_groups=' do
    include_context 'with discover groups and users'

    let(:added_group) { 'totally_new_group' }

    it 'allows addition of discover groups' do
      expect { manager.discover_groups = manager.discover_groups.to_a + [added_group] }
        .to change { manager.discover_groups }
        .to contain_exactly(public_group, custom_group, added_group)
    end

    it 'allows removal of discover groups' do
      expect { manager.discover_groups = [added_group] }
        .to change { manager.discover_groups }
        .to contain_exactly(added_group)
    end
  end

  describe '#discover_users' do
    it 'returns the empty for no discover users' do
      expect(manager.discover_users.to_a).to be_empty
    end

    context 'with discover groups and users' do
      include_context 'with discover groups and users'

      it 'gives all of and only the discover users' do
        expect(manager.discover_users)
          .to contain_exactly(user, other_user)
      end
    end
  end

  describe '#discover_users=' do
    include_context 'with discover groups and users'

    let(:added_user) { create(:user).user_key.to_s }

    it 'allows addition of discover users' do
      expect { manager.discover_users = manager.discover_users.to_a + [added_user] }
        .to change { manager.discover_users }
        .to contain_exactly(user, other_user, added_user)
    end

    it 'allows removal of discover users' do
      expect { manager.discover_users = [added_user] }
        .to change { manager.discover_users }
        .to contain_exactly(added_user)
    end
  end

  describe '#edit_groups' do
    it 'returns the empty for no edit groups' do
      expect(manager.edit_groups.to_a).to be_empty
    end

    context 'with edit groups and users' do
      include_context 'with edit groups and users'

      it 'gives all of and only the edit groups' do
        expect(manager.edit_groups)
          .to contain_exactly(public_group, custom_group)
      end
    end
  end

  describe '#edit_groups=' do
    include_context 'with edit groups and users'

    let(:added_group) { 'totally_new_group' }

    it 'allows addition of edit groups' do
      expect { manager.edit_groups = manager.edit_groups.to_a + [added_group] }
        .to change { manager.edit_groups }
        .to contain_exactly(public_group, custom_group, added_group)
    end

    it 'allows removal of edit groups' do
      expect { manager.edit_groups = [added_group] }
        .to change { manager.edit_groups }
        .to contain_exactly(added_group)
    end
  end

  describe '#edit_users' do
    it 'returns the empty for no edit users' do
      expect(manager.edit_users.to_a).to be_empty
    end

    context 'with edit groups and users' do
      include_context 'with edit groups and users'

      it 'gives all of and only the edit users' do
        expect(manager.edit_users)
          .to contain_exactly(user, other_user)
      end
    end
  end

  describe '#edit_users=' do
    include_context 'with edit groups and users'

    let(:added_user) { create(:user).user_key.to_s }

    it 'allows addition of edit users' do
      expect { manager.edit_users = manager.edit_users.to_a + [added_user] }
        .to change { manager.edit_users }
        .to contain_exactly(user, other_user, added_user)
    end

    it 'allows removal of edit users' do
      expect { manager.edit_users = [added_user] }
        .to change { manager.edit_users }
        .to contain_exactly(added_user)
    end
  end

  describe '#read_groups' do
    it 'returns the empty for no read groups' do
      expect(manager.read_groups.to_a).to be_empty
    end

    context 'with read groups and users' do
      include_context 'with read groups and users'

      it 'gives all of and only the read groups' do
        expect(manager.read_groups)
          .to contain_exactly(public_group, custom_group)
      end
    end
  end

  describe '#read_groups=' do
    include_context 'with read groups and users'

    let(:added_group) { 'totally_new_group' }

    it 'allows addition of read groups' do
      expect { manager.read_groups = manager.read_groups.to_a + [added_group] }
        .to change { manager.read_groups }
        .to contain_exactly(public_group, custom_group, added_group)
    end

    it 'allows removal of read groups' do
      expect { manager.read_groups = [added_group] }
        .to change { manager.read_groups }
        .to contain_exactly(added_group)
    end
  end

  describe '#read_users' do
    it 'returns the empty for no read users' do
      expect(manager.read_users.to_a).to be_empty
    end

    context 'with read groups and users' do
      include_context 'with read groups and users'

      it 'gives all of and only the read users' do
        expect(manager.read_users)
          .to contain_exactly(user, other_user)
      end
    end
  end

  describe '#read_users=' do
    include_context 'with read groups and users'

    let(:added_user) { create(:user).user_key.to_s }

    it 'allows addition of read users' do
      expect { manager.read_users = manager.read_users.to_a + [added_user] }
        .to change { manager.read_users }
        .to contain_exactly(user, other_user, added_user)
    end

    it 'allows removal of read users' do
      expect { manager.read_users = [added_user] }
        .to change { manager.read_users }
        .to contain_exactly(added_user)
    end
  end
end
