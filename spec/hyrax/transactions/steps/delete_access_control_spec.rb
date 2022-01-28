# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::DeleteAccessControl, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  context 'when acl has not been persisted' do
    it 'gives Success(obj) in basic case' do
      expect(step.call(work).value!).to eql(work)
    end
  end

  context 'when existing permissions exist' do
    let(:user) { FactoryBot.create(:user) }

    before do
      work.permission_manager.read_users = [user.user_key]
      work.permission_manager.acl.save
    end

    it 'deletes the access control resource' do
      expect { step.call(work) }
        .to change { Hyrax::AccessControl.for(resource: work).persisted? }
        .from(true)
        .to(false)
    end
  end

  context 'when the resource has no permission_manager' do
    before do
      module Hyrax
        module Test
          module DeleteAccessControlStep
            class SimpleResource < Valkyrie::Resource
            end
          end
        end
      end
    end

    after { Hyrax::Test.send(:remove_const, :DeleteAccessControlStep) }

    let(:resource) { Hyrax.persister.save(resource: Hyrax::Test::DeleteAccessControlStep::SimpleResource.new) }

    it 'succeeds happily' do
      expect(step.call(work).value!).to eql(work)
    end
  end
end
