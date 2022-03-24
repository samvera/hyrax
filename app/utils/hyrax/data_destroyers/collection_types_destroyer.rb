# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # Collection types are recreated by the release seed data.  Clear out here to
    # start with a fresh set.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    class CollectionTypesDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("CollectionTypesDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying collection types...")

          Hyrax::CollectionType.destroy_all
          logger.info("   collection types -- DESTROYED")
        end
      end
    end
  end
end
