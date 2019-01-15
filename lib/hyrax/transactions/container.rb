# frozen_string_literal: true
require "dry/transaction"
require "dry/transaction/operation"

module Hyrax
  module Transactions
    ##
    # Provides a container for transaction steps related to creating, updating,
    # and destroying PCDM Objects in Hyrax.
    #
    # In advanced use, the container could provide runtime dependency injection
    # for particular step code. For the basic case, users can consider it as
    # providing namespaceing and resolution for steps (as used in
    # `Hyrax::Transaction::CreateWork`; e.g.
    # `step :save_work, with: 'work.save_work'`).
    #
    # @since 2.4.0
    #
    # @see https://dry-rb.org/gems/dry-container/
    class Container
      require 'hyrax/transactions/create_work'
      require 'hyrax/transactions/destroy_work'
      require 'hyrax/transactions/steps/apply_permission_template'
      require 'hyrax/transactions/steps/destroy_work'
      require 'hyrax/transactions/steps/ensure_admin_set'
      require 'hyrax/transactions/steps/ensure_permission_template'
      require 'hyrax/transactions/steps/save_work'
      require 'hyrax/transactions/steps/set_default_admin_set'
      require 'hyrax/transactions/steps/set_modified_date'
      require 'hyrax/transactions/steps/set_uploaded_date'

      extend Dry::Container::Mixin

      namespace 'work' do |ops|
        ops.register 'apply_permission_template' do
          Steps::ApplyPermissionTemplate.new
        end

        ops.register 'destroy_work' do
          Steps::DestroyWork.new
        end

        ops.register 'ensure_admin_set' do
          Steps::EnsureAdminSet.new
        end

        ops.register 'ensure_permission_template' do
          Steps::EnsurePermissionTemplate.new
        end

        ops.register 'save_work' do
          Steps::SaveWork.new
        end

        ops.register 'set_default_admin_set' do
          Steps::SetDefaultAdminSet.new
        end

        ops.register 'set_modified_date' do
          Steps::SetModifiedDate.new
        end

        ops.register 'set_uploaded_date' do
          Steps::SetUploadedDate.new
        end
      end
    end
  end
end
