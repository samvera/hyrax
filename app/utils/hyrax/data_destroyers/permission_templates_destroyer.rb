# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # PermissionTemplates are tightly coupled to admin sets and collections.
    # When they are removed using wipe!, the associated database entries for
    # permission templates also have to be deleted.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    class PermissionTemplatesDestroyer
      class << self
        attr_accessor :logger

        def destroy_data(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("PermissionTemplatesDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying permission templates...")

          Hyrax::PermissionTemplateAccess.destroy_all
          logger.info("   permission templates access -- DESTROYED")

          Hyrax::PermissionTemplate.destroy_all
          logger.info("   permission templates -- DESTROYED")
        end
      end
    end
  end
end
