# frozen_string_literal: true

module Hyrax
  # This class was created for use in rake tasks and db/seeds.rb.  It generates
  # repository metadata needed for release testing.  This data can also be helpful
  # for local development testing.
  class TestDataSeeder
    attr_accessor :logger, :allow_seeding_in_production

    def initialize(logger: Logger.new(STDOUT), allow_seeding_in_production: false)
      raise("TestDataSeeder is not for use in production!") if Rails.env.production? && !allow_seeding_in_production
      @logger = logger
      @allow_seeding_in_production = allow_seeding_in_production
    end

    def generate_seed_data
      Hyrax::TestDataSeeders::UserSeeder.generate_seeds(logger: logger, allow_seeding_in_production: allow_seeding_in_production)
      Hyrax::TestDataSeeders::CollectionTypeSeeder.generate_seeds(logger: logger, allow_seeding_in_production: allow_seeding_in_production)
      Hyrax::TestDataSeeders::CollectionSeeder.generate_seeds(logger: logger, allow_seeding_in_production: allow_seeding_in_production)
      # TODO: add work seeder
      # Hyrax::TestDataSeeders::WorkSeeder.generate_seeds(logger: logger, allow_seeding_in_production: allow_seeding_in_production)
    end
  end
end
