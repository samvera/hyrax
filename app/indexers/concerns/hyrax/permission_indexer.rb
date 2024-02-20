# frozen_string_literal: true

module Hyrax
  ##
  # Indexes `*_groups`/`*_users` style permissions. We depend on these
  # permissions being up-to-date in the index to support `Hyrax::Ability`.
  #
  # @example
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::PermissionIndexer
  #   end
  module PermissionIndexer
    def to_solr
      super.tap do |index_document|
        config      = Hydra.config.permissions
        permissions = resource.permission_manager || Hyrax::PermissionManager.new(resource: resource)

        index_document[config.edit.group] = permissions.edit_groups.to_a
        index_document[config.edit.individual] = permissions.edit_users.to_a
        index_document[config.read.group] = permissions.read_groups.to_a
        index_document[config.read.individual] = permissions.read_users.to_a
      end
    end
  end
end
