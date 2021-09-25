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
    class Container # rubocop:disable Metrics/ClassLength
      require 'hyrax/transactions/apply_change_set'
      require 'hyrax/transactions/collection_create'
      require 'hyrax/transactions/create_work'
      require 'hyrax/transactions/destroy_work'
      require 'hyrax/transactions/file_set_destroy'
      require 'hyrax/transactions/work_create'
      require 'hyrax/transactions/work_destroy'
      require 'hyrax/transactions/update_work'
      require 'hyrax/transactions/steps/add_file_sets'
      require 'hyrax/transactions/steps/add_to_collections'
      require 'hyrax/transactions/steps/add_to_parent'
      require 'hyrax/transactions/steps/apply_collection_permission_template'
      require 'hyrax/transactions/steps/apply_collection_type_permissions'
      require 'hyrax/transactions/steps/apply_permission_template'
      require 'hyrax/transactions/steps/apply_visibility'
      require 'hyrax/transactions/steps/delete_resource'
      require 'hyrax/transactions/steps/destroy_work'
      require 'hyrax/transactions/steps/ensure_admin_set'
      require 'hyrax/transactions/steps/set_collection_type_gid'
      require 'hyrax/transactions/steps/ensure_permission_template'
      require 'hyrax/transactions/steps/remove_file_set_from_work'
      require 'hyrax/transactions/steps/save'
      require 'hyrax/transactions/steps/save_work'
      require 'hyrax/transactions/steps/save_access_control'
      require 'hyrax/transactions/steps/set_default_admin_set'
      require 'hyrax/transactions/steps/set_modified_date'
      require 'hyrax/transactions/steps/set_uploaded_date_unless_present'
      require 'hyrax/transactions/steps/set_user_as_depositor'
      require 'hyrax/transactions/steps/validate'

      extend Dry::Container::Mixin

      # Disable BlockLength rule for DSL code
      # rubocop:disable Metrics/BlockLength
      namespace 'change_set' do |ops|
        ops.register 'add_to_collections' do
          Steps::AddToCollections.new
        end

        ops.register 'apply' do
          ApplyChangeSet.new
        end

        ops.register 'create_collection' do
          CollectionCreate.new
        end

        ops.register 'create_work' do
          WorkCreate.new
        end

        ops.register 'ensure_admin_set' do
          Steps::EnsureAdminSet.new
        end

        ops.register 'save' do
          Steps::Save.new
        end

        ops.register 'set_collection_type_gid' do
          Steps::SetCollectionTypeGid.new
        end

        ops.register 'set_default_admin_set' do
          Steps::SetDefaultAdminSet.new
        end

        ops.register 'set_modified_date' do
          Steps::SetModifiedDate.new
        end

        ops.register 'set_uploaded_date_unless_present' do
          Steps::SetUploadedDateUnlessPresent.new
        end

        ops.register 'set_user_as_depositor' do
          Steps::SetUserAsDepositor.new
        end

        ops.register 'update_work' do
          UpdateWork.new
        end

        ops.register 'validate' do
          Steps::Validate.new
        end
      end

      namespace 'file_set' do |ops| # Hyrax::FileSet
        ops.register 'delete' do
          Steps::DeleteResource.new
        end

        ops.register 'destroy' do
          FileSetDestroy.new
        end

        ops.register 'remove_from_work' do
          Steps::RemoveFileSetFromWork.new
        end
      end

      namespace 'collection_resource' do |ops| # valkyrie collection
        ops.register 'apply_collection_type_permissions' do
          Steps::ApplyCollectionTypePermissions.new
        end

        ops.register 'save_acl' do
          Steps::SaveAccessControl.new
        end
      end

      namespace 'work_resource' do |ops| # valkyrie works
        ops.register 'add_file_sets' do
          Steps::AddFileSets.new
        end

        ops.register 'add_to_parent' do
          Steps::AddToParent.new
        end

        ops.register 'delete' do
          Steps::DeleteResource.new
        end

        ops.register 'destroy' do
          WorkDestroy.new
        end

        ops.register 'save_acl' do
          Steps::SaveAccessControl.new
        end
      end

      namespace 'work' do |ops| # legacy AF works
        ops.register 'apply_collection_permission_template' do
          Steps::ApplyCollectionPermissionTemplate.new
        end

        ops.register 'apply_permission_template' do
          Steps::ApplyPermissionTemplate.new
        end

        ops.register 'apply_visibility' do
          Steps::ApplyVisibility.new
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

        ops.register 'set_uploaded_date_unless_present' do
          Steps::SetUploadedDateUnlessPresent.new
        end
      end
      # rubocop:enable Metrics/BlockLength
    end
  end
end
