# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # Stats are tightly coupled to works and files in the repository. When they
    # are removed using wipe!, the associated database entries for stats also
    # need to be deleted.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    class StatsDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("StatsDataDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying stats...")

          FileDownloadStat.destroy_all
          logger.info("   file download stats -- DESTROYED")

          FileViewStat.destroy_all
          logger.info("   file view stats -- DESTROYED")

          WorkViewStat.destroy_all
          logger.info("   work view stats -- DESTROYED")
        end
      end
    end
  end
end
