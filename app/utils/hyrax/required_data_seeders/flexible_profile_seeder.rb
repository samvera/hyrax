# frozen_string_literal: true

module Hyrax
  module RequiredDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # collections that are required for all Hyrax applications.
    #
    # Seeders of required data are non-destructive.  If the data already exists,
    # it will not be replaced.
    class FlexibleProfileSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT))
          @logger = logger

          logger.info("Adding required collections...")

          flexible_schema = Hyrax::FlexibleSchema.first_or_create do |f|
            f.profile = YAML.safe_load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml'))
          end

          logger.info "   #{flexible_schema.title} -- FOUND OR CREATED"
        end
      end
    end
  end
end
