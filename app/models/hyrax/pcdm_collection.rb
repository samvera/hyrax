# frozen_string_literal: true

require_dependency 'hyrax/collection_name'

module Hyrax
  ##
  # Valkyrie model for Collection domain objects in the Hydra Works model.
  #
  # *Relationships:*
  #
  # Collection and Collection (TBA)
  #
  # Collection and Work
  # * Collection to Work (0..m):  A collection can have many works.  This relationship
  #   is defined by the inverse relationship stored in the work.
  #   * See Hyrax::Work for code to set the relationship.
  #   * Get works using: <code>works = Hyrax.custom_queries.find_members_of(collection: collection)</code>
  #   * See 'a Hyrax::Work' behaves_like 'belongs to collections' in
  #     /lib/hyrax/specs/shared_specs/hydra_works.rb for tests of this relationship.
  # * Work to Collection (0..m):  A work can be in many collections.  The
  #   relationship to the collection is defined in the work.
  #   * See Hyrax::Work for code to get and set collections for the work.
  # @note Some collection types limit a work to belong to one and only one collection of that type.
  #
  # @see Hyrax::Work
  # @see Hyrax::CustomQueries::Navigators::CollectionMembers#find_members_of
  # @see /lib/hyrax/specs/shared_specs/hydra_works.rb
  #
  class PcdmCollection < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)
    include Hyrax::Schema(:basic_metadata)

    attribute :collection_type_gid, Valkyrie::Types::String
    attribute :member_ids, Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
    attribute :member_of_collection_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)

    ##
    # @api private
    #
    # @return [Class] an ActiveModel::Name compatible class
    def self._hyrax_default_name_class
      Hyrax::CollectionName
    end

    ##
    # @return [Boolean] true
    def collection?
      true
    end

    ##
    # @return [Boolean] true
    def pcdm_object?
      true
    end

    def permission_manager
      @permission_manager ||= Hyrax::PermissionManager.new(resource: self)
    end

    def visibility=(value)
      visibility_writer.assign_access_for(visibility: value)
    end

    def visibility
      visibility_reader.read
    end

    protected

    def visibility_writer
      Hyrax::VisibilityWriter.new(resource: self)
    end

    def visibility_reader
      Hyrax::VisibilityReader.new(resource: self)
    end
  end
end
