# frozen_string_literal: true

require_dependency 'hyrax/collection_name'

module Hyrax
  ##
  # Valkyrie model for Collection domain objects in the Hydra Works model.
  #
  # ## Relationships
  #
  # ### Collection and Collection (TBA)
  #
  # ### Collection and Work
  #
  # * Defined: The relationship is defined by the inverse relationship stored in the
  #   work's `:member_of_collection_ids` attribute.
  # * Tested: The work tests the relationship.
  # * Collection to Work: (0..m)  A collection can have many works.
  #
  # @example Get works in a collection:
  #       works = Hyrax.custom_queries.find_child_works(resource: collection)
  #
  # * Work to Collection: (0..m)  A work can be in many collections.
  #   * See Hyrax::Work for code to get and set collections for the work.
  #
  # @note Some collection types limit a work to belong to one and only one collection of that type.
  #
  # ### All children
  #
  # * There are additional methods for finding all children without respect to
  #   the child's type.
  #
  # @example Get works and child collections in a collection using:
  #       members = Hyrax.custom_queries.find_members_of(resource: collection)
  #
  # @see Hyrax::Work
  #
  # @see Hyrax::CustomQueries::Navigators::ChildCollectionsNavigator#find_child_collections
  # @see Hyrax::CustomQueries::Navigators::ChildWorksNavigator#find_child_works
  # @see Hyrax::CustomQueries::Navigators::CollectionMembers#find_members_of
  #
  class PcdmCollection < Hyrax::Resource
    include Hyrax::Schema(:core_metadata) if Hyrax.config.collection_include_metadata?
    # The `redirects` attribute is registered directly on the resource class
    # (not via a schema YAML) so it is uniformly available across both
    # metadata modes (`flexible: false` and `flexible: true`). The attribute
    # is always defined; the `:redirects` Flipflop gates the user-facing
    # surfaces — the catch-all route, the controller, the form tab, the
    # validators — at request time, where the per-tenant Flipflop strategy
    # has the context it needs to answer correctly. Class-load-time gating
    # is not used here because (a) the Flipflop facade isn't initialized
    # when this class loads under Bulkrax's initializer, and (b) class
    # definitions can't vary per tenant in any case.
    #
    # Set (rather than Array) so instance round-trips through assignment
    # don't re-invoke the Dry::Struct constructor on existing entries
    # (Array.of(Resource) raises "can't convert Object into Hash" on
    # collection.redirects = collection.redirects).
    attribute :redirects, Valkyrie::Types::Set.of(Hyrax::Redirect)

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
    def self.pcdm_collection?
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
