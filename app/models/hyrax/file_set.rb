# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `FileSet` domain objects in the Hydra Works model.
  #
  # ## Relationships
  #
  # ### FileSet and Work
  #
  # * Defined: The relationship is defined by the inverse relationship stored in the
  #   work's `:member_ids` attribute.
  # * Tested: The test for the Work class tests the relationship.
  # * FileSet to Work: (n..1)  A FileSet must be in one and only one work. A Work can have zero to many FileSets.
  # * See Hyrax::Work for code to get and set file sets for the work.
  #
  # @example Get Work for a FileSet:
  #       work = Hyrax.custom_queries.find_parent_work(resource: file_set)
  #
  # ### FileSet and FileMetadata
  #
  # * Defined: The relationship is defined by the FileSet's `:file_ids` attribute.
  # * FileSet to FileMetadata: (0..n) A FileSet can have many FileMetadatas. A FileMetadata must be in one and only one FileSet.
  #
  # @example Get all FileMetadata for a FileSet:
  #     file_metadata = Hyrax.custom_queries.find_files(file_set: file_set)
  #
  # @example Attach a File to a FileSet through a FileMetadata. This will create
  #   a FileMetadata for a File object, attach the File to the FileMetadata, and
  #   attach that FileMetadata to a given FileSet.
  #     ::Hyrax::ValkyrieUpload.file(
  #       io: file_io,
  #       filename: "myfile.jpg",
  #       file_set: file_set,
  #       use: pcdm_use,
  #       user: user
  #     )
  #
  # ### FileMetadata and Files
  #
  # * Defined: The relationship is defined by the FileMetadata's `:file_identifier` attribute.
  # * FileMetadata to File: (1..1) A FileMetadata can have one and only one File
  #
  # @example Get a File for a FileMetadata
  #     file = Hyrax.storage_adapter.find_by(id: file_metadata.file_identifier)
  #
  # @see Hyrax::Work
  # @see Hyrax::CustomQueries::Navigators::FindFiles#find_files
  # @see Hyrax::CustomQueries::Navigators::ParentWorkNavigator#find_parent_work
  # @see https://wiki.duraspace.org/display/samvera/Hydra%3A%3AWorks+Shared+Modeling
  class FileSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)
    include Hyrax::Schema(:file_set_metadata)

    def self.model_name(name_class: Hyrax::Name)
      @_model_name ||= name_class.new(self, nil, 'FileSet')
    end

    class_attribute :characterization_proxy
    self.characterization_proxy = Hyrax.config.characterization_proxy

    attribute :file_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID) # id for FileMetadata resources

    # @return [Hyrax::FileMetadata, nil]
    def original_file
      Hyrax.custom_queries.find_original_file(file_set: self)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    # @return [Valkyrie::ID, nil]
    def original_file_id
      original_file&.id
    end

    # @return [Hyrax::FileMetadata, nil]
    def thumbnail
      Hyrax.custom_queries.find_thumbnail(file_set: self)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    # @return [Valkyrie::ID, nil]
    def thumbnail_id
      thumbnail&.id
    end

    # @return [Hyrax::FileMetadata, nil]
    def extracted_text
      Hyrax.custom_queries.find_extracted_text(file_set: self)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end

    # @return [Valkyrie::ID, nil]
    def extracted_text_id
      extracted_text&.id
    end

    ##
    # @return [Valkyrie::ID]
    def representative_id
      id
    end

    ##
    # @return [Boolean] true
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] true
    def file_set?
      true
    end
  end
end
