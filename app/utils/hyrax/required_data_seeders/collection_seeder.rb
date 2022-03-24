

# frozen_string_literal: true
module Hyrax
  module RequiredDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # collections that are required for all Hyrax applications.
    #
    # Seeders of required data are non-destructive.  If the data already exists,
    # it will not be replaced.
    class CollectionSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT))
          @logger = logger

          logger.info("Adding required collections...")

          default_admin_set = Hyrax::AdminSetCreateService.find_or_create_default_admin_set
          logger.info "   #{default_admin_set.title.first} -- FOUND OR CREATED"
        end
      end
    end
  end
end
