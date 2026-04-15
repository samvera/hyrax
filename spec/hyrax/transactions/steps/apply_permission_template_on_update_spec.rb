# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::ApplyPermissionTemplateOnUpdate, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }

  context 'when admin set has not changed' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_default_admin_set) }

    it 'returns success without modifying permissions' do
      original_edit_users = work.edit_users.to_a.dup
      result = step.call(work)

      expect(result).to be_success
      expect(result.value!.edit_users.to_a).to eq original_edit_users
    end
  end

  context 'when admin set has changed and both templates exist' do
    let(:old_manager) { FactoryBot.create(:user) }
    let(:new_manager) { FactoryBot.create(:user) }
    let(:shared_manager) { FactoryBot.create(:user) }

    let(:old_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: old_manager).tap do |admin_set|
        template = Hyrax::PermissionTemplate.find_by(source_id: admin_set.id.to_s)
        template.access_grants.create!(agent_type: 'user', agent_id: shared_manager.user_key, access: 'manage')
      end
    end

    let(:new_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: new_manager).tap do |admin_set|
        template = Hyrax::PermissionTemplate.find_by(source_id: admin_set.id.to_s)
        template.access_grants.create!(agent_type: 'user', agent_id: shared_manager.user_key, access: 'manage')
      end
    end

    let(:work) do
      w = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set, admin_set: new_admin_set)
      # Simulate old template grants still being on the work
      w.edit_users += [old_manager.user_key, shared_manager.user_key]
      # Attach the previous_admin_set_id as the Save step would
      old_id = old_admin_set.id.to_s
      w.define_singleton_method(:previous_admin_set_id) { old_id }
      w
    end

    it 'removes old-only grants and adds new grants' do
      result = step.call(work)

      expect(result).to be_success
      value = result.value!
      expect(value.edit_users.to_a).to include(new_manager.user_key)
      expect(value.edit_users.to_a).to include(shared_manager.user_key)
      expect(value.edit_users.to_a).not_to include(old_manager.user_key)
    end
  end

  context 'when old template is missing' do
    let(:new_manager) { FactoryBot.create(:user) }

    let(:new_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: new_manager)
    end

    let(:work) do
      w = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set, admin_set: new_admin_set)
      w.define_singleton_method(:previous_admin_set_id) { 'nonexistent-admin-set-id' }
      w
    end

    it 'applies new template without error' do
      result = step.call(work)

      expect(result).to be_success
      expect(result.value!.edit_users.to_a).to include(new_manager.user_key)
    end
  end

  context 'when new template is missing' do
    let(:old_manager) { FactoryBot.create(:user) }

    let(:old_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: old_manager)
    end

    let(:work) do
      w = FactoryBot.valkyrie_create(:hyrax_work)
      w.edit_users += [old_manager.user_key]
      old_id = old_admin_set.id.to_s
      w.define_singleton_method(:previous_admin_set_id) { old_id }
      w
    end

    it 'removes old grants and logs a warning' do
      expect(Hyrax.logger).to receive(:warn).with(/doesn't have a PermissionTemplate/)

      result = step.call(work)

      expect(result).to be_success
      expect(result.value!.edit_users.to_a).not_to include(old_manager.user_key)
    end
  end

  context 'when depositor has edit access from old template' do
    let(:depositor) { FactoryBot.create(:user) }

    let(:old_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: depositor)
    end

    let(:new_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template)
    end

    let(:work) do
      w = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set, admin_set: new_admin_set, depositor: depositor.user_key)
      w.edit_users += [depositor.user_key]
      old_id = old_admin_set.id.to_s
      w.define_singleton_method(:previous_admin_set_id) { old_id }
      w
    end

    it 'removes depositor template grant like any other old grant' do
      result = step.call(work)

      expect(result).to be_success
      # The depositor's old template manage grant is removed because it is not
      # in the new template. The depositor's access is restored downstream by
      # save_acl which persists permissions from the depositor field.
      expect(result.value!.edit_users.to_a).not_to include(depositor.user_key)
    end
  end

  context 'when manually added permissions exist' do
    let(:manual_user) { FactoryBot.create(:user) }
    let(:old_manager) { FactoryBot.create(:user) }

    let(:old_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: old_manager)
    end

    let(:new_admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template)
    end

    let(:work) do
      w = FactoryBot.valkyrie_create(:hyrax_work, :with_admin_set, admin_set: new_admin_set)
      w.edit_users += [old_manager.user_key, manual_user.user_key]
      old_id = old_admin_set.id.to_s
      w.define_singleton_method(:previous_admin_set_id) { old_id }
      w
    end

    it 'preserves manually added permissions' do
      result = step.call(work)

      expect(result).to be_success
      expect(result.value!.edit_users.to_a).to include(manual_user.user_key)
      expect(result.value!.edit_users.to_a).not_to include(old_manager.user_key)
    end
  end
end
