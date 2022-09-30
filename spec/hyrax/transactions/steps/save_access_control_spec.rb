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

      it 'transforms and persists the params' do
        expect { step.call(work, permissions_params: params) }
          .to change { Hyrax::AccessControlList.new(resource: work).permissions }
          .to contain_exactly(have_attributes(mode: :read, agent: user.user_key),
                                    have_attributes(mode: :edit, agent: user.user_key),
                                    have_attributes(mode: :read, agent: 'group/admin'))
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
