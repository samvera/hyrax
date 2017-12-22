module Hyrax
  #
  # Methods for Querying Repository to find Embargoed Objects
  #
  class EmbargoService < RestrictionService
    class << self
      # Finds the existing embargo or creates a new one.
      # @param resource [Valkyrie::Resource] typically a work or fileset. This will be mutated to set the embargo_id
      # @param embargo_params [Array] A tuple of arity 3 with the embargo information
      # @return [Void]
      def apply_embargo(resource:, embargo_params:)
        embargo = find_or_initialize_embargo(resource)

        embargo.embargo_release_date = [DateTime.parse(embargo_params[0]).in_time_zone]
        embargo.visibility_during_embargo = embargo_params[1]
        embargo.visibility_after_embargo = embargo_params[2]
        saved = persister.save(resource: embargo)

        resource.embargo_id = saved.id
        resource.assign_embargo_visibility(embargo)
      end

      def persister
        Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      end
      private :persister

      def find_or_initialize_embargo(resource)
        if resource.embargo_id
          Hyrax::Queries.find_by(id: resource.embargo_id)
        else
          Hyrax::Embargo.new
        end
      end
      private :find_or_initialize_embargo

      # Returns all assets with embargo release date set to a date in the past
      def assets_with_expired_embargoes
        builder = Hyrax::ExpiredEmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets with embargo release date set
      #   (assumes that when lease visibility is applied to assets
      #    whose leases have expired, the lease expiration date will be removed from its metadata)
      def assets_under_embargo
        builder = Hyrax::EmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_embargoes
        builder = Hyrax::DeactivatedEmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      private

        def presenter_class
          Hyrax::EmbargoPresenter
        end
    end
  end
end
