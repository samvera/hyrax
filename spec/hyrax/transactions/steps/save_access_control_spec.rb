# frozen_string_literal: true
require 'spec_helper'
require 'hyrax/transactions'

RSpec.describe Hyrax::Transactions::Steps::SaveAccessControl, valkyrie_adapter: :test_adapter do
  subject(:step) { described_class.new }
  let(:work)     { FactoryBot.valkyrie_create(:hyrax_work) }

  it 'gives Success(obj) in basic case' do
    expect(step.call(work).value!).to eql(work)
  end

  context 'when editing permissions' do
    let(:user) { FactoryBot.create(:user) }

    before { work.permission_manager.acl.grant(:read).to(user) }

    it 'persists the new permissions' do
      expect { step.call(work) }
        .to change { Hyrax::AccessControlList.new(resource: work).permissions }
        .to contain_exactly(have_attributes(mode: :read, agent: user.user_key))
    end
  end

  context 'when the resource has no permission_manager' do
    before do
      module Hyrax
        module Test
          module SaveAccessControlStep
            class SimpleResource < Valkyrie::Resource
            end
          end
        end
      end
    end

    after { Hyrax::Test.send(:remove_const, :SaveAccessControlStep) }

    let(:resource) { Hyrax.persister.save(resource: Hyrax::Test::SaveAccessControlStep::SimpleResource.new) }

    it 'succeeds happily' do
      expect(step.call(work).value!).to eql(work)
    end
  end
end
