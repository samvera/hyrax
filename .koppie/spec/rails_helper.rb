# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'valkyrie'
Valkyrie::MetadataAdapter.register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)
Valkyrie::StorageAdapter.register(Valkyrie::Storage::Memory.new, :memory)

query_registration_target =
  Valkyrie::MetadataAdapter.find(:test_adapter).query_service.custom_queries
custom_queries = [Hyrax::CustomQueries::Navigators::CollectionMembers,
                  Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
                  Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
                  Hyrax::CustomQueries::FindAccessControl,
                  Hyrax::CustomQueries::FindCollectionsByType,
                  Hyrax::CustomQueries::FindManyByAlternateIds,
                  Hyrax::CustomQueries::FindIdsByModel,
                  Hyrax::CustomQueries::FindFileMetadata,
                  Hyrax::CustomQueries::Navigators::FindFiles]
custom_queries.each do |handler|
  query_registration_target.register_query_handler(handler)
end

# Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  # config.use_active_record = false
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
