# frozen_string_literal: true
require "dry/transaction"
require "dry/transaction/operation"

module Hyrax
  module Transactions
    class Container
      require 'hyrax/transactions/create_work'
      require 'hyrax/transactions/steps/ensure_admin_set'
      require 'hyrax/transactions/steps/ensure_permission_template'
      require 'hyrax/transactions/steps/save_work'
      require 'hyrax/transactions/steps/set_default_admin_set'
      require 'hyrax/transactions/steps/set_modified_date'
      require 'hyrax/transactions/steps/set_uploaded_date'

      extend Dry::Container::Mixin

      namespace 'work' do |ops|
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
