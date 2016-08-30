module CurationConcerns
  class EmbargoService < RestrictionService
    class << self
      #
      # Methods for Querying Repository to find Embargoed Objects
      #

      # Returns all assets with embargo release date set to a date in the past
      def assets_with_expired_embargoes
        builder = CurationConcerns::ExpiredEmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets with embargo release date set
      #   (assumes that when lease visibility is applied to assets
      #    whose leases have expired, the lease expiration date will be removed from its metadata)
      def assets_under_embargo
        builder = CurationConcerns::EmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      # Returns all assets that have had embargoes deactivated in the past.
      def assets_with_deactivated_embargoes
        builder = CurationConcerns::DeactivatedEmbargoSearchBuilder.new(self)
        presenters(builder)
      end

      private

        def presenter_class
          CurationConcerns::EmbargoPresenter
        end
    end
  end
end
