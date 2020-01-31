# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `FileSet` domain objects in the Hydra Works model.
  #
  # @see https://wiki.duraspace.org/display/samvera/Hydra%3A%3AWorks+Shared+Modeling
  class FileSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :file_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID) # id for FileMetadata resources

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
