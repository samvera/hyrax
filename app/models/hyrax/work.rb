# frozen_string_literal: true

module Hyrax
  ##
  # Valkyrie model for `Work` domain objects in the Hydra Works model.
  #
  # *Relationships:*
  #
  # Administrative Set and Work
  #
  # * <b>Defined:</b> The relationship is defined by the work's `:admin_set_id` attribute.
  # * <b>Tested:</b> The relationship is tested in shared spec 'a Hyrax::Work' by testing
  #   `#admin_set_id`.  Shared specs are defined in /lib/hyrax/specs/shared_specs/hydra_works.rb.
  # * <b>Administrative Set to Work:</b> (1..m) An admin set can have many works.
  #   * See Hyrax::AdministrativeSet for code to get works in an admin set.
  # * <b>Work to Administrative Set:</b> (1..1)  A work must be in one and only one admin set.
  #   * Set admin set for a work using:
  #       work.admin_set_id = admin_set.id
  #   * Get admin set a work is in using:
  #       admin_set = Hyrax.query_service.find_by(id: work.admin_set_id)
  #
  # Collection and Work
  #
  # * <b>Defined:</b> The relationship is defined by the work's `:member_of_collection_ids` attribute.
  # * <b>Tested:</b> The relationship is tested in shared spec 'a Hyrax::Work' by testing
  #   `it_behaves_like 'belongs to collections'`.  Shared specs are defined in /lib/hyrax/specs/shared_specs/hydra_works.rb.
  # * <b>Collection to Work:</b> (0..m)  A collection can have many works.
  #   * See Hyrax::PcdmCollection for code to get works in a collection.
  # * <b>Work to Collection:</b> (0..m)  A work can be in many collections.
  #   * Add a work to a collection using Hyrax::CollectionMemberService (multiple method options)
  #       Hyrax::CollectionMemberService.add_members(collection_id: col.id, members: works, user: current_user)
  #   * Get collections a work is in using:
  #       collections = Hyrax.custom_queries.find_collections_for(resource: work)
  # @note Some collection types limit a work to belong to one and only one collection of that type.
  #
  # Work and Work
  #
  # * <b>Defined:</b> The relationship is defined in the parent work's `:member_ids` attribute.
  # * <b>Tested:</b> The relationship is tested in shared spec 'a Hyrax::Work' by testing
  #   `it_behaves_like 'has_members'`.  Shared specs are defined in /lib/hyrax/specs/shared_specs/hydra_works.rb.
  # * <b>Work to child Work:</b> (0..m)  A work can have many child works.
  #   * Add a child work to a work using:
  #       Hyrax::Transactions::Container['work_resource.add_to_parent']
  #         .call(child_work, parent_id: parent_work.id, user: current_user)
  #   * Get child works using:
  #       works = Hyrax.custom_queries.find_child_works(resource: parent_work)
  # * <b>Work to parent Work:</b> (0..1)  A work can be in at most one parent work.
  #   * Get parent work using:
  #       parent_work = Hyrax.custom_queries.find_parent_work(resource: child_work)
  # @note `:member_ids` holds ids of child works and file sets.
  #
  # Work and File Set (TBD)
  #
  # @see Hyrax::AdministrativeSet
  # @see Hyrax::PcdmCollection
  # @see Hyrax::FileSet
  #
  # @see Hyrax::CollectionMemberService
  # @see Hyrax::Transactions::Steps::AddToParent
  #
  # @see Valkyrie query adapter's #find_by
  # @see Hyrax::CustomQueries::Navigators::CollectionMembers#find_collections_for
  # @see Hyrax::CustomQueries::Navigators::CollectionMembers#find_parent_work
  #
  # @see /lib/hyrax/specs/shared_specs/hydra_works.rb
  #
  # @todo The description in Hydra::Works Shared Modeling is out of date and uses
  #   terminology to describe the relationships that is no longer used in code.
  #   Update the model and link to it.  This can be a simple relationship diagram
  #   with a link to the original Works Shared Modeling for historical perspective.
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
