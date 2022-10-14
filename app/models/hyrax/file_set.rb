# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `FileSet` domain objects in the Hydra Works model.
  #
  # ## Relationships
  #
  # ### File Set and Work
  #
  # * Defined: The relationship is defined by the inverse relationship stored in the
  #   work's `:member_ids` attribute.
  # * Tested: The work tests the relationship.
  # * File Set to Work: (1..1)  A file set must be in one and only one work.
  #
  # @example Get work for a file set:
  #       work = Hyrax.custom_queries.find_parent_work(resource: file_set)
  #
  # * Work to File Set: (0..m)  A work can have many file sets.
  #   * See Hyrax::Work for code to get and set file sets for the work.
  #
  # ### File Set and File (TBD)
  #
  # @see Hyrax::Work
  # @see Hyrax::CustomQueries::Navigators::ParentWorkNavigator#find_parent_work
  #
  # @todo The description in Hydra::Works Shared Modeling is out of date and uses
  #   terminology to describe the relationships that is no longer used in code.
  #   Update the model and link to it.  This can be a simple relationship diagram
  #   with a link to the original Works Shared Modeling for historical perspective.
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
    attribute :thumbnail_id, Valkyrie::Types::ID.optional # id for FileMetadata resource
    attribute :original_file_id, Valkyrie::Types::ID.optional # id for FileMetadata resource
    attribute :extracted_text_id, Valkyrie::Types::ID.optional # id for FileMetadata resource

    ##
    # @return [Valkyrie::ID]
    def representative_id
      id
    end

    ##
    # @return [Valkyrie::ID]
    # If one is set then return it, otherwise use self as the ID to allow for
    # derivative generators to find the on-disk path for the thumbnail.
    def thumbnail_id
      self.[](:thumbnail_id) || id
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
