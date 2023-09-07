# frozen_string_literal: true
RSpec.describe Hyrax::Collections::PermissionsService do
  subject(:service) { described_class }
  let(:user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(user) }

  context 'methods querying individual collections' do
    let(:collection) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: grants)
    end

    let(:grants) { [] }

    context 'when manage user' do
      let(:grants) do
        [{ agent_type: 'user', access: 'manage', agent_id: user.user_key }]
      end

      it '.can_deposit_in_collection? returns true' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end

      it '.can_view_admin_show_for_collection? returns true' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end
    end

    context 'when deposit user' do
      let(:grants) do
        [{ agent_type: 'user', access: 'deposit', agent_id: user.user_key }]
      end

      it '.can_deposit_in_collection? returns true' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end

      it '.can_view_admin_show_for_collection? returns true' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end
    end

    context 'when view user' do
      let(:grants) do
        [{ agent_type: 'user', access: 'view', agent_id: user.user_key }]
      end

      it '.can_deposit_in_collection? returns false' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end

      it '.can_view_admin_show_for_collection? returns true' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end
    end

    context 'when deposit user through membership in public group' do
      let(:grants) do
        [{ agent_type: 'group', access: 'deposit', agent_id: 'public' }]
      end

      it '.can_deposit_in_collection? returns true' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end

      it '.can_view_admin_show_for_collection? returns false' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end
    end

    context 'when deposit user through membership in registered group' do
      let(:grants) do
        [{ agent_type: 'group', access: 'deposit', agent_id: 'registered' }]
      end

      it '.can_deposit_in_collection? returns true' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be true
      end

      it '.can_view_admin_show_for_collection? returns false' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end
    end

    context 'when view user through membership in public group' do
      let(:grants) do
        [{ agent_type: 'group', access: 'view', agent_id: 'public' }]
      end

      it '.can_deposit_in_collection? returns false' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end

      it '.can_view_admin_show_for_collection? returns false' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end
    end

    context 'when view user through membership in registered group' do
      let(:grants) do
        [{ agent_type: 'group', access: 'view', agent_id: 'registered' }]
      end

      it '.can_deposit_in_collection? returns false' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end

      it '.can_view_admin_show_for_collection? returns false' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end
    end

    context 'when user without access' do
      it '.can_deposit_in_collection? returns false' do
        expect(service.can_deposit_in_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end

      it '.can_view_admin_show_for_collection? returns false' do
        expect(service.can_view_admin_show_for_collection?(collection_id: collection.id, ability: ability))
          .to be false
      end
    end
  end

  context 'methods querying access to many collections' do
    let(:user) do
      FactoryBot.create(:user, groups: ['view_group',
                                        'deposit_group',
                                        'manage_group'])
    end

    let(:other_user) { FactoryBot.create(:user) }

    let!(:col_view_user) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'view',
                                                   agent_id: user.user_key }])
    end

    let!(:col_view_group) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'view',
                                                   agent_id: 'view_group' }])
    end

    let!(:col_manage_user) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'manage',
                                                   agent_id: user.user_key }])
    end

    let!(:col_manage_group) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'manage',
                                                   agent_id: 'manage_group' }])
    end

    let!(:col_deposit_user) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'deposit',
                                                   agent_id: user.user_key }])
    end

    let!(:col_deposit_group) do
      FactoryBot.valkyrie_create(:hyrax_collection,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'deposit',
                                                   agent_id: 'deposit_group' }])
    end

    let!(:as_view_user) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'view',
                                                   agent_id: user.user_key }])
    end

    let!(:as_view_group) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'view',
                                                   agent_id: 'view_group' }])
    end

    let!(:as_manage_user) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'manage',
                                                   agent_id: user.user_key }])
    end

    let!(:as_manage_group) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'manage',
                                                   agent_id: 'manage_group' }])
    end

    let!(:as_deposit_user) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'user',
                                                   access: 'deposit',
                                                   agent_id: user.user_key }])
    end

    let!(:as_deposit_group) do
      FactoryBot.valkyrie_create(:hyrax_admin_set,
                                 :with_permission_template,
                                 access_grants: [{ agent_type: 'group',
                                                   access: 'deposit',
                                                   agent_id: 'deposit_group' }])
    end

    describe '.collection_ids_for_user' do
      it 'returns collection ids where user has manage access' do
        expect(described_class.collection_ids_for_user(access: 'manage', ability: ability))
          .to contain_exactly(col_manage_user.id, col_manage_group.id)
      end

      it 'returns collection ids where user has deposit access' do
        expect(described_class.collection_ids_for_user(access: 'deposit', ability: ability))
          .to contain_exactly(col_deposit_user.id, col_deposit_group.id)
      end

      it 'returns collection ids where user has view access' do
        expect(described_class.collection_ids_for_user(access: 'view', ability: ability))
          .to contain_exactly(col_view_user.id, col_view_group.id)
      end

      it 'returns collection ids where user has manage, deposit, or view access' do
        all = [col_manage_user.id, col_manage_group.id, col_deposit_user.id, col_deposit_group.id, col_view_user.id, col_view_group.id]

        expect(described_class.collection_ids_for_user(access: ['manage', 'deposit', 'view'], ability: ability))
          .to contain_exactly(*all)
      end

      it 'returns empty arraywhen user has no access' do
        expect(described_class.collection_ids_for_user(access: ['manage', 'deposit', 'view'], ability: Ability.new(other_user)))
          .to be_empty
      end
    end

    describe '.source_ids_for_manage' do
      it 'returns collection and admin set ids where user has manage access' do
        expect(described_class.source_ids_for_manage(ability: ability))
          .to contain_exactly(col_manage_user.id,
                              col_manage_group.id,
                              as_manage_user.id,
                              as_manage_group.id)
      end

      it 'returns collection ids where user has manage access' do
        expect(described_class.source_ids_for_manage(ability: ability, source_type: 'collection'))
          .to contain_exactly(col_manage_user.id, col_manage_group.id)
      end

      it 'returns admin set ids where user has manage access' do
        expect(described_class.source_ids_for_manage(ability: ability, source_type: 'admin_set'))
          .to contain_exactly(as_manage_user.id, as_manage_group.id)
      end

      context 'when user has no access' do
        it 'returns empty array' do
          expect(described_class.source_ids_for_manage(ability: Ability.new(other_user)))
            .to be_empty
        end
      end
    end

    describe '.source_ids_for_deposit' do
      it 'returns collection and admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(ability: ability))
          .to contain_exactly(col_deposit_user.id,
                              col_deposit_group.id,
                              col_manage_user.id,
                              col_manage_group.id,
                              as_deposit_user.id,
                              as_deposit_group.id,
                              as_manage_user.id,
                              as_manage_group.id)
      end

      it 'returns collection ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(ability: ability, source_type: 'collection'))
          .to contain_exactly(col_deposit_user.id,
                              col_deposit_group.id,
                              col_manage_user.id,
                              col_manage_group.id)
      end

      it 'returns admin set ids where user has deposit access' do
        expect(described_class.source_ids_for_deposit(ability: ability, source_type: 'admin_set'))
          .to contain_exactly(as_deposit_user.id,
                              as_deposit_group.id,
                              as_manage_user.id,
                              as_manage_group.id)
      end

      it 'returns admin set ids where user has deposit access except excluded groups' do
        expect(described_class.source_ids_for_deposit(ability: ability, source_type: 'admin_set', exclude_groups: ['deposit_group']))
          .to contain_exactly(as_deposit_user.id, as_manage_user.id, as_manage_group.id)
      end

      it 'returns empty array when user has no access' do
        expect(described_class.source_ids_for_deposit(ability: Ability.new(other_user)))
          .to be_empty
      end
    end

    describe '.collection_ids_for_deposit' do
      it 'returns collection ids where user has manage access' do
        expect(described_class.collection_ids_for_deposit(ability: ability))
          .to contain_exactly(col_deposit_user.id, col_deposit_group.id, col_manage_user.id, col_manage_group.id)
      end

      it 'returns empty array' do
        expect(described_class.collection_ids_for_deposit(ability: Ability.new(other_user)))
          .to be_empty
      end
    end

    describe '.collection_ids_for_view' do
      it 'returns collection ids where user has view access' do
        expect(described_class.collection_ids_for_view(ability: ability))
          .to contain_exactly(col_deposit_user.id,
                              col_deposit_group.id,
                              col_manage_user.id,
                              col_manage_group.id,
                              col_view_user.id,
                              col_view_group.id)
      end

      it 'returns empty array when user has no access' do
        expect(described_class.collection_ids_for_view(ability: Ability.new(other_user)))
          .to be_empty
      end
    end

    describe '.can_manage_any_collection?' do
      it 'returns true when user has manage access to at least one collection' do
        expect(described_class.can_manage_any_collection?(ability: ability))
          .to be true
      end

      it 'returns false when user has no access' do
        expect(described_class.can_manage_any_collection?(ability: Ability.new(other_user)))
          .to be false
      end
    end

    describe '.can_manage_any_admin_set?' do
      it 'returns true when user has manage access to at least one admin set' do
        expect(described_class.can_manage_any_admin_set?(ability: ability)).to be true
      end

      it 'returns false when user has no access' do
        expect(described_class.can_manage_any_admin_set?(ability: Ability.new(other_user)))
          .to be false
      end
    end

    describe '.can_view_admin_show_for_any_collection?' do
      it 'returns true when user has manage, deposit, or view access to at least one collection' do
        expect(described_class.can_view_admin_show_for_any_collection?(ability: ability))
          .to be true
      end

      it 'returns false when user has no access' do
        expect(described_class.can_view_admin_show_for_any_collection?(ability: Ability.new(other_user)))
          .to be false
      end
    end

    describe '.can_view_admin_show_for_any_admin set?' do
      it 'returns true when user has manage, deposit, or view access to at least one admin set' do
        expect(described_class.can_view_admin_show_for_any_admin_set?(ability: ability))
          .to be true
      end

      it 'returns false when user has no access' do
        expect(described_class.can_view_admin_show_for_any_admin_set?(ability: Ability.new(other_user)))
          .to be false
      end
    end
  end
end
