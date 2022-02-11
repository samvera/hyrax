# frozen_string_literal: true

require_dependency 'hyrax/administrative_set_name'

module Hyrax
  ##
  # Valkyrie model for Admin Set domain objects.
  #
  # ## Relationships
  #
  # ### Administrative Set and Work
  #
  # * Defined: The relationship is defined by the inverse relationship stored in the
  #   work's `:admin_set_id` attribute.
  # * Tested: The work tests the relationship.
  # * Administrative Set to Work: (1..m)  An admin set can have many works.
  #
  # @example Get works in an admin set:
  #       works = Hyrax.query_service.find_inverse_references_by(id: admin_set.id, property: :admin_set_id)
  #
  # * Work to Administrative Set: (1..1)  A work must be in one and only one admin set.
  #   * See Hyrax::Work for code to get and set the admin set for the work.
  #
  # @see Hyrax::Work
  # @see Valkyrie query adapter's #find_inverse_references_by
  #
  class AdministrativeSet < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :alternative_title, Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :creator,           Valkyrie::Types::Set.of(Valkyrie::Types::String)
    attribute :description,       Valkyrie::Types::String

    ##
    # @return [Boolean] true
    def collection?
      true
    end

    def collection_type_gid
      # allow AdministrativeSet to behave more like a regular PcdmCollection
      Hyrax::CollectionType.find_or_create_admin_set_type.to_global_id
    end

    ##
    # @api private
    #
    # @return [Class] an ActiveModel::Name compatible class
    def self._hyrax_default_name_class
      Hyrax::AdministrativeSetName
    end
  end
end
