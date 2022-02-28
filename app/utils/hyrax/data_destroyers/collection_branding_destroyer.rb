# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # Collection branding info is tightly coupled to collections.  When they are
    # removed using wipe!, the associated database entries for collection branding
    # also have to be deleted.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    # @todo This destroys branding info in the database.  Should it also delete
    #   related banner and logo files?
    class CollectionBrandingDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("CollectionBrandingDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying collection branding...")

          Hyrax::CollectionBrandingInfo.destroy_all
          logger.info("   collection branding -- DESTROYED")
        end
      end
    end
  end
end
