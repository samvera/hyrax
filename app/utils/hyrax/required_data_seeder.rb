# frozen_string_literal: true
module Hyrax
  # This class was created for use in rake tasks and db/seeds.rb.  It generates
  # required repository metadata including Admin Set and User collection types and
  # the default admin set.
  #
  # Seeders of required data are non-destructive.  If the data already exists,
  # it will not be replaced.
  class RequiredDataSeeder
    attr_accessor :logger

    def initialize(logger: Logger.new(STDOUT))
      @logger = logger
    end

    def generate_seed_data
      Hyrax::RequiredDataSeeders::CollectionTypeSeeder.generate_seeds(logger: logger)
      Hyrax::RequiredDataSeeders::CollectionSeeder.generate_seeds(logger: logger)
    end
  end
end
