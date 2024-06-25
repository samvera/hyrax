# frozen_string_literal: true

module Hyrax
  ##
  # Provides methods for dealing with versions of files across both ActiveFedora
  # and Valkyrie.
  #
  # Note that many of the methods pertaining to version creation are currently
  # implemented as static methods.
  class VersioningService
    ##
    # @!attribute [rw] resource
    #   @return [ActiveFedora::File | Hyrax::FileMetadata | NilClass]
    attr_accessor :resource

    ##
    # @!attribute [r] storage_adapter
    #   @return [#supports?]
    attr_reader :storage_adapter

    ##
    # @param resource [ActiveFedora::File | Hyrax::FileMetadata | NilClass]
    def initialize(resource:, storage_adapter: nil)
      @storage_adapter = if storage_adapter.nil?
                           if resource.respond_to?(:file_identifier)
                             Valkyrie::StorageAdapter.adapter_for(id: resource.file_identifier)
                           else
                             Hyrax.storage_adapter
                           end
                         else
                           storage_adapter
                         end
      self.resource = resource
    end

    ##
    # Returns an array of versions for the resource associated with this
    # Hyrax::VersioningService.
    #
    # If the resource is nil, or if it is a Hyrax::FileMetadata and versioning
    # is not supported in the storage adapter, an empty array will be returned.
    def versions
      if !supports_multiple_versions?
        []
      elsif resource.is_a?(Hyrax::FileMetadata)
        # Reverse - Valkyrie puts these most recent first, we assume most recent
        # last.
        storage_adapter.find_versions(id: resource.file_identifier).to_a.reverse
      else
        return resource.versions if resource.versions.is_a?(Array)
        resource.versions.all.to_a
      end
    end

    ##
    # Returns the latest version of the file associated with this
    # Hyrax::VersioningService.
    def latest_version
      versions.last
    end

    ##
    # Returns whether support for multiple versions exists on this
    # +Hyrax::VersioningService+.
    #
    # Versioning is unsupported on nil resources or on Valkyrie resources when
    # the configured storage adapter does not advertise versioning support.
    def supports_multiple_versions?
      !(resource.nil? || resource.is_a?(Hyrax::FileMetadata) && !storage_adapter.try(:"supports?", :versions))
    end

    ##
    # Returns the file ID of the latest version of the file associated with this
    # Hyrax::VersioningService, or the ID of the file resource itself if no
    # latest version is defined.
    #
    # If the resource is nil, this method returns an empty string.
    def versioned_file_id
      latest = latest_version
      if latest && !resource.is_a?(Hyrax::FileMetadata)
        if latest.respond_to?(:id)
          latest.id
        else
          Hyrax.config.translate_uri_to_id.call(latest.uri)
        end
      elsif resource.nil?
        ""
      elsif resource.is_a?(Hyrax::FileMetadata)
        latest_version&.version_id || resource.file_identifier
      else
        resource.id
      end
    end

    class << self
      # Make a version and record the version committer
      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      # @param [User, String] user
      def create(content, user = nil, file = nil)
        use_valkyrie = content.is_a? Hyrax::FileMetadata
        perform_create(content, user, file, use_valkyrie)
      end

      # @param [ActiveFedora::File | Hyrax::FileMetadata] file
      def latest_version_of(file)
        Hyrax::VersioningService.new(resource: file).latest_version
      end

      # @param [ActiveFedora::File | Hyrax::FileMetadata] file
      def versioned_file_id(file)
        Hyrax::VersioningService.new(resource: file).versioned_file_id
      end

      # Record the version committer of the last version
      # @param [ActiveFedora::File | Hyrax::FileMetadata] content
      # @param [User, String] user_key
      def record_committer(content, user_key)
        user_key = user_key.user_key if user_key.respond_to?(:user_key)
        version = latest_version_of(content)
        return if version.nil?
        version_id = content.is_a?(Hyrax::FileMetadata) ? version.version_id.to_s : version.uri
        Hyrax::VersionCommitter.create(version_id: version_id, committer_login: user_key)
      end

      private

      def perform_create(content, user, file, use_valkyrie)
        use_valkyrie ? perform_create_through_valkyrie(content, file, user) : perform_create_through_active_fedora(content, user)
      rescue NotImplementedError
        Hyrax.logger.warn "Declining to create a Version for #{content}; #{self} doesn't support versioning with use_valkyrie: #{use_valkyrie}"
      end

      def perform_create_through_active_fedora(content, user)
        content.create_version
        record_committer(content, user) if user
      end

      def perform_create_through_valkyrie(content, file, user)
        raise NotImplementedError unless Hyrax.storage_adapter.supports?(:versions)
        Hyrax.storage_adapter.upload_version(id: content.file_identifier, file: file)
        record_committer(content, user) if user
      end

      def storage_adapter
        Hyrax.storage_adapter
      end
    end
  end
end
