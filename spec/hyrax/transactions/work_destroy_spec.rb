# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::WorkDestroy do
  subject(:transaction) { described_class.new }
  let(:work)      { FactoryBot.valkyrie_create(:hyrax_work, read_users: [user], members: [file_set]) }
  let(:file_set)  { FactoryBot.valkyrie_create(:hyrax_file_set) }

  describe '#call' do
    let(:user) { FactoryBot.create(:user) }

    context 'without a user' do
      it 'is a failure' do
        expect(transaction.call(work)).to be_failure
      end
    end

    it 'succeeds' do
      expect(transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work))
        .to be_success
    end

    it 'deletes the work' do
      transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

      expect { Hyrax.query_service.find_by(id: work.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'deletes the file set' do
      transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

      expect { Hyrax.query_service.find_by(id: file_set.id) }
        .to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'deletes the access control resource' do
      expect { transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work) }
        .to change { Hyrax::AccessControl.for(resource: work).persisted? }
        .from(true).to(false)
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
        transaction.with_step_args('work_resource.delete_all_file_sets' => { user: user }).call(work)

        expect { Hyrax.query_service.find_by(id: file_metadata.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
        expect { storage_adapter.find_by(id: uploaded.id) }.to raise_error Valkyrie::StorageAdapter::FileNotFound
      end
    end
  end
end
