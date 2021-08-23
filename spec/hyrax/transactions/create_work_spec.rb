# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::CreateWork do
  subject(:transaction) { described_class.new }
  let(:template)        { Hyrax::PermissionTemplate.find_by!(source_id: work.admin_set_id) }
  let(:work)            { build(:generic_work) }
  let(:xmas)            { DateTime.parse('2018-12-25 11:30').iso8601 }

  before do
    Hyrax::PermissionTemplate
      .find_or_create_by(source_id: Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s)
  end

  describe '#call' do
    context 'with an invalid work' do
      let(:work) { build(:invalid_generic_work) }

      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end

      it 'does not save the work' do
        expect { transaction.call(work) }.not_to change { work.new_record? }.from true
      end

      it 'gives useful errors' do
        expect(transaction.call(work).failure).to eq work.errors
      end
    end

    it 'is a success' do
      expect(transaction.call(work)).to be_success
    end

    it 'persists the work' do
      expect { transaction.call(work) }
        .to change { work.persisted? }
        .to true
    end

    it 'sets visibility to restricted by default' do
      expect { transaction.call(work) }
        .not_to change { work.visibility }
        .from Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    it 'sets the default admin set' do
      expect { transaction.call(work) }
        .to change { work.admin_set&.id }
        .to Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
    end

    it 'sets the modified time using Hyrax::TimeService' do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect { transaction.call(work) }.to change { work.date_modified }.to xmas
    end

    it 'sets the created time using Hyrax::TimeService' do
      allow(Hyrax::TimeService).to receive(:time_in_utc).and_return(xmas)

      expect { transaction.call(work) }.to change { work.date_uploaded }.to xmas
    end

    it 'grants edit permission to depositor' do
      transaction.call(work)

      expect(work.edit_users).to include work.depositor
    end
  end

  context 'when visibility is set' do
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    before { work.visibility = visibility }

    it 'keeps the visibility' do
      expect { transaction.call(work) }
        .not_to change { work.visibility }
        .from visibility
    end
  end

  context 'when requesting a lease' do
    let(:after)     { 'restricted' }
    let(:during)    { 'open' }
    let(:end_date)  { (Time.zone.today + 2).to_s }
    let(:request)   { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE }
    let(:step_args) { { apply_visibility: [visibility: request, release_date: end_date, during: during, after: after] } }

    it 'sets the lease' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.lease }
        .to be_a_lease_matching(release_date: end_date, during: during, after: after)
    end
  end

  context 'when requesting an embargo' do
    let(:after)     { 'open' }
    let(:during)    { 'restricted' }
    let(:end_date)  { (Time.zone.today + 2).to_s }
    let(:request)   { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO }
    let(:step_args) { { apply_visibility: [visibility: request, release_date: end_date, during: during, after: after] } }

    it 'sets the embargo' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.embargo }
        .to be_an_embargo_matching(release_date: end_date, during: during, after: after)
    end
  end

  context 'with an admin set' do
    let(:admin_set) { AdminSet.find(template.source_id) }
    let(:template)  { create(:permission_template, with_admin_set: true) }
    let(:work)      { build(:generic_work, admin_set: admin_set) }

    context 'without a permission template' do
      let(:admin_set) { create(:admin_set, with_permission_template: false) }

      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end

      it 'is does not persist the work' do
        expect { transaction.call(work) }
          .not_to change { work.persisted? }
          .from false
      end
    end

    it 'is a success' do
      expect(transaction.call(work)).to be_success
    end

    it 'retains the set admin set' do
      expect { transaction.call(work) }
        .not_to change { work.admin_set&.id }
        .from admin_set.id
    end

    context 'with users and groups' do
      let(:manage_groups) { ['manage_group_1', 'manage_group_2'] }
      let(:manage_users)  { create_list(:user, 2) }
      let(:view_groups)   { ['view_group_1', 'view_group_2'] }
      let(:view_users)    { create_list(:user, 2) }

      let(:template) do
        create(:permission_template,
               with_admin_set: true,
               manage_groups: manage_groups,
               manage_users: manage_users,
               view_groups: view_groups,
               view_users: view_users)
      end

      it 'assigns edit groups from template' do
        expect { transaction.call(work) }
          .to change { work.edit_groups }
          .to include(*manage_groups)
      end

      it 'assigns edit users from template' do
        expect { transaction.call(work) }
          .to change { work.edit_users }
          .to include(*manage_users.map(&:user_key))
      end

      it 'assigns read groups from template' do
        expect { transaction.call(work) }
          .to change { work.read_groups }
          .to include(*view_groups)
      end

      it 'assigns read users from template' do
        expect { transaction.call(work) }
          .to change { work.read_users }
          .to include(*view_users.map(&:user_key))
      end
    end
  end

  context 'when inheriting permissions from a collection' do
    let(:manage_groups) { ['edit_group_1', 'edit_group_2'] }
    let(:manage_users)  { create_list(:user, 2) }
    let(:view_groups)   { ['read_group_1', 'read_group_2'] }
    let(:view_users)    { create_list(:user, 2) }
    let(:collection)    { create(:collection_lw, with_permission_template: permissions) }
    let(:step_args)     { { apply_collection_template: [collections: [collection]] } }

    let(:permissions) do
      { manage_groups: manage_groups,
        manage_users: manage_users,
        view_groups: view_groups,
        view_users: view_users }
    end

    it 'assigns edit groups from template' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.edit_groups }
        .to include(*manage_groups)
    end

    it 'assigns edit users from template' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.edit_users }
        .to include(*manage_users.map(&:user_key))
    end

    it 'assigns read groups from template' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.read_groups }
        .to include(*view_groups)
    end

    it 'assigns read users from template' do
      expect { transaction.with_step_args(step_args).call(work) }
        .to change { work.read_users }
        .to include(*view_users.map(&:user_key))
    end
  end
end
