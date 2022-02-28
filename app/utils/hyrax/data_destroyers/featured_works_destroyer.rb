# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # Featured works are tightly coupled to works in the repository. When they
    # are removed using wipe!, the associated database entries for featured
    # works also need to be deleted.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    class FeaturedWorksDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("FeaturedWorksDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying featured works...")

          FeaturedWork.destroy_all
          logger.info("   featured works -- DESTROYED")
        end
      end
    end
  end
end
