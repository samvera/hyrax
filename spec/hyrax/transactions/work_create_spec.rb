# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::WorkCreate, :clean_repo do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { build(:hyrax_work) }
  let(:default_admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved work' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    it 'sets the default admin set' do
      expect(tx.call(change_set).value!)
        .to have_attributes admin_set_id: default_admin_set_id
    end

    context 'when an admin set is already assigned to the work' do
      let(:admin_set) { valkyrie_create(:hyrax_admin_set) }
      let(:resource) { build(:hyrax_work, admin_set_id: admin_set.id) }

      it 'keeps the existing admin set' do
        expect(tx.call(change_set).value!)
          .to have_attributes admin_set_id: admin_set.id
      end
    end

    context 'when providing a depositor' do
      let(:user) { FactoryBot.create(:user) }

      it 'sets the given user as the depositor' do
        tx.with_step_args('change_set.set_user_as_depositor' => { user: user })

        expect(tx.call(change_set).value!)
          .to have_attributes depositor: user.user_key
      end

      it 'grants the depositor edit access on the work ACL' do
        work = tx.with_step_args('change_set.set_user_as_depositor' => { user: user })
                 .call(change_set)
                 .value!

        edit_agents = Hyrax::AccessControlList.new(resource: work)
                                              .permissions
                                              .select { |p| p.mode == :edit }
                                              .map(&:agent)
        expect(edit_agents).to include(user.user_key)
      end
    end

    # @see https://github.com/notch8/hykuup_knapsack/issues/608
    #
    # Regression introduced when Hyrax moved from the ActiveFedora actor stack
    # (where Hyrax::Actors::BaseActor#apply_depositor_metadata unconditionally
    # added the depositor to the work's edit_users) to the Valkyrie WorkCreate
    # transaction (which does not). Under workflows whose deposit action does
    # not include Hyrax::Workflow::GrantEditToDepositor -- notably
    # one_step_mediated_deposit -- depositors lose edit access to their own
    # works after creation.
    context 'when depositing into an admin set whose active workflow does not grant edit to the depositor' do
      let(:user) { FactoryBot.create(:user) }
      let(:admin_set) do
        allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('one_step_mediated_deposit')
        as = Hyrax.config.admin_set_class.new(title: ['Mediated Deposit Admin Set'])
        Hyrax::AdminSetCreateService.call!(admin_set: as, creating_user: nil)
      end
      let(:resource) { build(:hyrax_work, admin_set_id: admin_set.id) }

      before do
        # The mediated workflow's deposit action triggers PendingReviewNotification,
        # which requires registered curation_concern URL helpers that the test
        # SimpleWork model does not have. Skip notification delivery; we only
        # care about ACL state.
        allow(Hyrax::Workflow::NotificationService).to receive(:deliver_on_action_taken)
      end

      it 'still grants the depositor edit access on the work ACL' do
        work = tx.with_step_args('change_set.set_user_as_depositor' => { user: user })
                 .call(change_set)
                 .value!

        edit_agents = Hyrax::AccessControlList.new(resource: work)
                                              .permissions
                                              .select { |p| p.mode == :edit }
                                              .map(&:agent)
        expect(edit_agents).to include(user.user_key)
      end
    end

    context 'when attaching uploaded files' do
      let(:uploaded_files) { FactoryBot.create_list(:uploaded_file, 4) }

      it 'adds uploaded files' do
        tx.with_step_args('work_resource.add_file_sets' => { uploaded_files: uploaded_files })

        expect(tx.call(change_set).value!)
          .to have_file_set_members(be_persisted, be_persisted, be_persisted, be_persisted)
      end
    end

    context 'when providing a proxy_depositor' do
      let(:user) { FactoryBot.create(:user) }
      let(:on_behalf_of) { FactoryBot.create(:user) }
      let(:resource) { build(:hyrax_work, depositor: user.user_key) }

      it 'sets the given user as depositor, old depositor as proxy_depositor' do
        tx.with_step_args('work_resource.change_depositor' => { user: on_behalf_of })

        expect(tx.call(change_set).value!)
          .to have_attributes(
            proxy_depositor: user.user_key,
            depositor: on_behalf_of.user_key
          )
      end
    end
  end
end
