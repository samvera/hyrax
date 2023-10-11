# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions/steps/remove_file_set_related_objects'
require 'dry/container/stub'

RSpec.describe Hyrax::Transactions::Steps::RemoveFileSetRelatedObjects, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_one_file_set) }
  let(:file_set) { Hyrax.query_service.find_members(resource: work).first }

  describe '#call' do
    it 'is a Failure' do
      expect { step.call }.to raise_error(ArgumentError)
    end

    context 'with a work with a file set' do
      before do
        file_set.permission_manager.read_users = [user.user_key]
        file_set.permission_manager.acl.save
      end

      it 'calls a method to delete file_metadata' do
        expect(step).to receive(:remove_file_metadata)
        step.call(work)
      end

      it 'deletes the access control resource' do
        expect { step.call(work) }
          .to change { Hyrax::AccessControl.for(resource: file_set).persisted? }
          .from(true)
          .to(false)
      end
    end
  end
end
