# frozen_string_literal: true

module Hyrax
  ##
  # These methods created for use in rake tasks and db/seeds.rb  They can be used to:
  # * clear repository metadata and related data and files
  # * clear temporary files
  # * clear logs
  #
  # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
  #   Data can not be recovered.
  #
  class DataMaintenance
    attr_accessor :logger, :allow_destruction_in_production

    def initialize(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
      raise("Destruction of data is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
      @logger = logger
      @allow_destruction_in_production = allow_destruction_in_production
    end

    # Clear repository metadata and related data
    # * clear repository metadata from the datastore (e.g. Fedora, Postgres) and from Solr
    # * clear targeted application data that is tightly coupled to repository metadata
    # * delete files that are tightly coupled to repository metadata
    def destroy_repository_metadata_and_related_data
      Hyrax::DataDestroyers::RepositoryMetadataDestroyer.destroy_metadata(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::StatsDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::FeaturedWorksDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::PermissionTemplatesDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::CollectionBrandingDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::DefaultAdminSetIdCacheDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
      Hyrax::DataDestroyers::CollectionTypesDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)

      # TODO: Stubbed until RepositoryFilesDestroyer is written
      # Hyrax::DataDestroyers::RepositoryFilesDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
    end

    # @todo write code to clear out log files
    def destroy_log_files
      # Stubbed until LogFilesDestroyer is written
      # Hyrax::DataDestroyers::LogFilesDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
    end

    # @todo write code to delete tmp files
    def destroy_tmp_files
      # Stubbed until TmpFilesDestroyer is written
      # Hyrax::DataDestroyers::TmpFilesDestroyer.destroy_data(logger: logger, allow_destruction_in_production: allow_destruction_in_production)
    end
  end
end
