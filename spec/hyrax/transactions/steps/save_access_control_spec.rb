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

    context 'when it fails to update' do
      before { allow_any_instance_of(Hyrax::AccessControlList).to receive(:save).and_return(false) }

      it 'returns a Failure' do
        result = step.call(work)

        expect(result).to be_failure
        expect(result.failure).to contain_exactly(Symbol, Hyrax::AccessControlList)
      end
    end

    context 'when permissions params are passed' do
      let(:params) { [{ "access" => "read", "type" => "group", "name" => "admin" }, { "access" => "edit", "type" => "person", "name" => user.user_key }] }

      it 'transforms and persists the params, replacing the level a user had' do
        expect { step.call(work, permissions_params: params) }
          .to change { Hyrax::AccessControlList.new(resource: work).permissions }
          .to contain_exactly(have_attributes(mode: :edit, agent: user.user_key),
                              have_attributes(mode: :read, agent: 'group/admin'))
      end

      context 'when a param marks a grant for removal' do
        let(:other_user) { FactoryBot.create(:user) }
        let(:params) { [{ "access" => "read", "type" => "person", "name" => user.user_key, "_destroy" => "true" }] }

        before do
          work.permission_manager.acl.grant(:edit).to(other_user)
          work.permission_manager.acl.save
        end

        it 'revokes that grant and keeps the rest' do
          step.call(work, permissions_params: params)
          expect(Hyrax::AccessControlList.new(resource: work).permissions)
            .to contain_exactly(have_attributes(mode: :edit, agent: other_user.user_key))
        end
      end

      context 'when an earlier step changed a grant the form sends back unchanged' do
        let(:group) { Hyrax::Group.new('archivists') }
        let(:params) { [{ "access" => "read", "type" => "group", "name" => "archivists" }] }

        before do
          work.permission_manager.acl.grant(:read).to(group)
          work.permission_manager.acl.save
          work.permission_manager.acl.revoke(:read).from(group)
        end

        it 'keeps the earlier step\'s change' do
          step.call(work, permissions_params: params)
          expect(Hyrax::AccessControlList.new(resource: work).permissions)
            .not_to include(have_attributes(agent: 'group/archivists'))
        end
      end

      context 'when the form changes a saved grant\'s level' do
        let(:params) { [{ "access" => "edit", "type" => "person", "name" => user.user_key }] }

        before { work.permission_manager.acl.save }

        it 'replaces the saved level' do
          step.call(work, permissions_params: params)
          expect(Hyrax::AccessControlList.new(resource: work).permissions)
            .to contain_exactly(have_attributes(mode: :edit, agent: user.user_key))
        end
      end

      context 'when an agent has two saved levels and the form keeps one' do
        let(:params) { [{ "access" => "read", "type" => "person", "name" => user.user_key }, { "access" => "read", "type" => "person", "name" => user.user_key }] }

        before do
          work.permission_manager.acl.grant(:edit).to(user)
          work.permission_manager.acl.save
        end

        it 'leaves only the level the form sent' do
          step.call(work, permissions_params: params)
          expect(Hyrax::AccessControlList.new(resource: work).permissions)
            .to contain_exactly(have_attributes(mode: :read, agent: user.user_key))
        end
      end

      context 'with invalid params' do
        let(:params) { [{ "access" => "read", "type" => "group" }, { "type" => "person", "name" => "foo@bar.com" }, { "access" => "edit", "name" => "foo@bar.com" }] }

        it 'does not persist the params' do
          step.call(work, permissions_params: params)
          expect(Hyrax::AccessControlList.new(resource: work).permissions).to contain_exactly(have_attributes(mode: :read, agent: user.user_key))
        end
      end
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
