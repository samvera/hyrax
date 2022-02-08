# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `Work` domain objects in the Hydra Works model.
  #
  # *Relationships:*
  # * Administrative Set and Work
  #   * Administrative Set to Work (1..m): An admin set can have many works.  This relationship
  #     is defined by the inverse relationship stored in the work's attribute `:admin_set_id`.
  #     * See Hyrax::AdministrativeSet for code to get works in an admin set.
  #   * Work to Administrative Set (1..1):  A work must be in one and only one admin set.  The
  #     relationship to the admin set is defined in the work's attribute `:admin_set_id`.
  #     * Set admin set for work using: <code>work.admin_set_id = admin_set.id</code>
  #     * Get admin set resource using: <code>admin_set = Hyrax.query_service.find_by(id: work.admin_set_id)</code>
  #     * See 'a Hyrax::Work #admin_set_id' in /lib/hyrax/specs/shared_specs/hydra_works.rb
  #       for tests of this relationship.
  # * Collection and Work (TBD)
  # * Work and Work (TBD)
  # * Work and File Set (TBD)
  #
  # @see Hyrax::AdministrativeSet
  # @see Valkyrie query adapter's #find_by
  # @see /lib/hyrax/specs/shared_specs/hydra_works.rb
  #
  # TODO: The description in Hydra::Works Shared Modeling is out of date and uses
  # terminology to describe the relationships that is no longer used in code.
  # Update the model and link to it.  This can be a simple relationship diagram
  # with a link to the original Works Shared Modeling for historical perspective.
  # @see https://wiki.lyrasis.org/display/samvera/Hydra::Works+Shared+Modeling
  class Work < Hyrax::Resource
    include Hyrax::Schema(:core_metadata)

    attribute :admin_set_id,             Valkyrie::Types::ID
    attribute :member_ids,               Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
    attribute :member_of_collection_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID)
    attribute :on_behalf_of,             Valkyrie::Types::String
    attribute :proxy_depositor,          Valkyrie::Types::String
    attribute :state,                    Valkyrie::Types::URI.default(Hyrax::ResourceStatus::ACTIVE)
    attribute :rendering_ids,            Valkyrie::Types::Array.of(Valkyrie::Types::ID).meta(ordered: true)
    attribute :representative_id,        Valkyrie::Types::ID
    attribute :thumbnail_id,             Valkyrie::Types::ID

    ##
    # @return [Boolean] true
    def pcdm_object?
      true
    end

    ##
    # @return [Boolean] true
    def work?
      true
    end
  end
end
