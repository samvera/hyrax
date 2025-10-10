# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::FileSetCreate, :clean_repo do
  subject(:tx)     { described_class.new }
  let(:change_set) { Hyrax::ChangeSet.for(resource) }
  let(:resource)   { build(:hyrax_file_set) }
  let(:default_admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }

  describe '#call' do
    it 'is a success' do
      expect(tx.call(change_set)).to be_success
    end

    it 'wraps a saved file set' do
      expect(tx.call(change_set).value!).to be_persisted
    end

    context 'when providing a depositor' do
      let(:user) { FactoryBot.create(:user) }

      it 'sets the given user as the depositor' do
        tx.with_step_args('change_set.set_user_as_depositor' => { user: user })

        expect(tx.call(change_set).value!)
          .to have_attributes depositor: user.user_key
      end
    end

    context 'when attaching uploaded file' do
      let(:uploaded_file) { FactoryBot.create(:uploaded_file) }

      it 'adds uploaded files' do
        pending('Getting the uploaded file to attach correctly')
        tx.with_step_args('file_set.add_file' => { uploaded_file: uploaded_file })

        expect(tx.call(change_set).value!)
          .to have_attached_files(be_original_file)
      end
    end

    context 'when providing a proxy_depositor' do
      let(:user) { FactoryBot.create(:user) }
      let(:on_behalf_of) { FactoryBot.create(:user) }
      let(:resource) { build(:hyrax_work, depositor: user.user_key) }

      it 'sets the given user as depositor, old depositor as proxy_depositor' do
        pending('Adding a change depositor step for the file set')
        # We should probably do this as well, how should we call it?
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
