# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::FileSetDestroy do
  subject(:transaction) { described_class.new }
  let(:file_set)        { FactoryBot.valkyrie_create(:hyrax_file_set) }

  describe '#call' do
    let(:user) { FactoryBot.create(:user) }

    before do
      file_set.permission_manager.read_users = [user.user_key]
      file_set.permission_manager.acl.save
    end

    context 'without a user' do
      it 'is a failure' do
        expect(transaction.call(file_set)).to be_failure
      end
    end

    it 'succeeds' do
      expect(transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set))
        .to be_success
    end

    it 'deletes the file set' do
      transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set)

      expect { Hyrax.query_service.find_by(id: file_set.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'deletes the access control resource' do
      expect { transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set) }
        .to change { Hyrax::AccessControl.for(resource: file_set).persisted? }
        .from(true)
        .to(false)
    end

    context "with attached files" do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, uploaded_files: [FactoryBot.create(:uploaded_file)], edit_users: [user]) }
      let(:file_set) { query_service.find_members(resource: work).first }
      let(:file_metadata) { query_service.custom_queries.find_files(file_set: file_set).first }
      let(:uploaded) { storage_adapter.find_by(id: file_metadata.file_identifier) }
      let(:storage_adapter) { Hyrax.storage_adapter }
      let(:query_service) { Hyrax.query_service }
      it "deletes them" do
        file_metadata
        transaction.with_step_args('file_set.remove_from_work' => { user: user }).call(file_set)

        expect { Hyrax.query_service.find_by(id: file_metadata.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect { storage_adapter.find_by(id: uploaded.id) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end
  end
end
