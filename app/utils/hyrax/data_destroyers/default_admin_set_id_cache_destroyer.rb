# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # When the default admin set is removed using wipe!, the cache of the default
    # admin set id also needs to be deleted.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    class DefaultAdminSetIdCacheDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("DefaultAdminSetIdCacheDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying default admin set id cache...")

          Hyrax::DefaultAdministrativeSet.destroy_all
          logger.info("   default admin set id cache -- DESTROYED")
        end
      end
    end
  end
end
