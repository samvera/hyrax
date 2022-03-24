# frozen_string_literal: true
module Hyrax
  module RequiredDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # collection types that are required for all Hyrax applications.
    #
    # Seeders of required data are non-destructive.  If the data already exists,
    # it will not be replaced.
    class CollectionTypeSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT))
          @logger = logger

          logger.info("Adding required collection types...")

          as_ct = Hyrax::CollectionType.find_or_create_admin_set_type
          set_badge_color(as_ct, '#990000')
          logger.info("   #{as_ct.title} -- FOUND OR CREATED")

          user_ct = Hyrax::CollectionType.find_or_create_default_collection_type
          set_badge_color(user_ct, '#0099cc')
          logger.info("   #{user_ct.title} -- FOUND OR CREATED")
        end

        private

        def set_badge_color(collection_type, badge_color = nil)
          collection_type.badge_color = badge_color
          collection_type.save
        end
      end
    end
  end
end
