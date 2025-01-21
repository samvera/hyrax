# frozen_string_literal: true
$VERBOSE = nil unless ENV['RUBY_LOUD'] # silence loud Ruby 2.7 deprecations
ENV['RAILS_ENV'] = 'test'
ENV['DATABASE_URL'] = ENV['DATABASE_TEST_URL'] if ENV['DATABASE_TEST_URL']

# Analytics is turned off by default
ENV['HYRAX_ANALYTICS'] = 'false'

require "bundler/setup"

def ci_build?
  ENV['CI']
end

require 'simplecov'
SimpleCov.root(File.expand_path('../..', __FILE__))

SimpleCov.start('rails') do
  add_filter '/lib/generators'
  add_filter '/spec'
  add_filter '/tasks'
  add_filter '/lib/hyrax/version.rb'
  add_filter '/lib/hyrax/engine.rb'
end

require 'factory_bot'

require File.expand_path("config/environment", ENV['RAILS_ROOT'])
db_config = ActiveRecord::Base.configurations.configs_for(env_name: ENV['RAILS_ENV'])[0]
ActiveRecord::Tasks::DatabaseTasks.create(db_config)
ActiveRecord::Migrator.migrations_paths = [Pathname.new(ENV['RAILS_ROOT']).join('db', 'migrate').to_s]
ActiveRecord::Tasks::DatabaseTasks.migrate
ActiveRecord::Base.descendants.each(&:reset_column_information)
ActiveRecord::Migration.maintain_test_schema!

require 'active_fedora/cleaner'
require 'devise'
require 'devise/version'
require 'mida'
require 'rails-controller-testing'
require 'rspec/rails'
require 'rspec/its'
require 'rspec/matchers'
require 'rspec/active_model/mocks'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
require 'database_cleaner'

require 'hyrax/specs/capybara'
require 'hyrax/specs/clamav'
require 'hyrax/specs/engine_routes'

require 'rubocop'
require 'rubocop/rspec/support'

# ensure Hyrax::Schema gets loaded is resolvable for `support/` models
Hyrax::Schema # rubocop:disable Lint/Void

Valkyrie::MetadataAdapter
  .register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)
Valkyrie::MetadataAdapter
  .register(Valkyrie::Persistence::Postgres::MetadataAdapter.new, :postgres_adapter)
Valkyrie::MetadataAdapter
  .register(Freyja::MetadataAdapter.new, :freyja_adapter)
version_path = Rails.root / 'tmp' / 'test_adapter_uploads'
Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::VersionedDisk.new(base_path: version_path),
  :test_disk
)
FileUtils.mkdir_p(version_path)

Valkyrie::StorageAdapter.register(
  Valkyrie::Storage::Disk.new(base_path: File.expand_path('../fixtures', __FILE__)),
  :fixture_disk
)

# Because we're relying on shared specs from Valkyrie, and assuming that all of the classes will
# respond to #to_rdf_representation and the base Valkyrie::Resource does not do that nor does the
# dynamic classes generated for the shared specs; we need the following coercion.
module Hyrax::Resource::Coercible
  extend ActiveSupport::Concern

  class_methods do
    def to_rdf_representation
      name.to_s
    end
  end

  def to_rdf_representation
    self.class.to_rdf_representation
  end
end

Valkyrie::Resource.include(Hyrax::Resource::Coercible)

# Require supporting ruby files from spec/support/ and subdirectories.  Note: engine, not Rails.root context.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

require 'webmock/rspec'
allowed_hosts = %w[chrome chromedriver.storage.googleapis.com fcrepo solr]
WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_hosts)

require 'i18n/debug' if ENV['I18N_DEBUG']
require 'byebug' unless ci_build?

require 'hyrax/specs/shared_specs/factories/strategies/json_strategy'
require 'hyrax/specs/shared_specs/factories/strategies/valkyrie_resource'
FactoryBot.register_strategy(:valkyrie_create, ValkyrieCreateStrategy)
FactoryBot.register_strategy(:json, JsonStrategy)
FactoryBot.definition_file_paths = [File.expand_path("../../lib/hyrax/specs/shared_specs/factories", __FILE__)]
FactoryBot.find_definitions
require 'rspec/mocks'

require 'shoulda/matchers'
require 'shoulda/callback/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

query_registration_targets = [
  Valkyrie::MetadataAdapter.find(:test_adapter).query_service.custom_queries,
  Valkyrie::MetadataAdapter.find(:postgres_adapter).query_service.custom_queries
]
[Hyrax::CustomQueries::Navigators::CollectionMembers,
 Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator,
 Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator, # deprecated, use ChildFileSetsNavigator
 Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
 Hyrax::CustomQueries::Navigators::ParentWorkNavigator,
 Hyrax::CustomQueries::FindAccessControl,
 Hyrax::CustomQueries::FindCollectionsByType,
 Hyrax::CustomQueries::FindManyByAlternateIds,
 Hyrax::CustomQueries::FindIdsByModel,
 Hyrax::CustomQueries::FindFileMetadata,
 Hyrax::CustomQueries::Navigators::FindFiles].each do |handler|
  query_registration_targets.each do |adapter|
    adapter.register_query_handler(handler)
  end
end

ActiveJob::Base.queue_adapter = :test

def clean_active_fedora_repository
  return if Hyrax.config.disable_wings
  ActiveFedora::Cleaner.clean!
  # The JS is executed in a different thread, so that other thread
  # may think the root path has already been created:
  ActiveFedora.fedora.connection.send(:init_base_path)
end

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.include Shoulda::Matchers::ActiveRecord, type: :model
  config.include Shoulda::Matchers::ActiveModel, type: :form
  config.include Shoulda::Callback::Matchers::ActiveModel
  config.include Hyrax::Matchers
  config.full_backtrace = true if ci_build?
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.fixture_paths = [File.expand_path("../fixtures", __FILE__)]
  config.file_fixture_path = File.expand_path("../fixtures", __FILE__)
  config.use_transactional_fixtures = false

  config.before :suite do
    FactoryBot::SyntaxRunner.include ActiveJob::TestHelper
    FactoryBot::SyntaxRunner.include RSpec::Mocks::ExampleMethods
    # Workarounds for perform_enqueued_jobs
    FactoryBot::SyntaxRunner.include ActiveSupport::Testing::TaggedLogging
    # See https://github.com/rspec/rspec-rails/issues/2545
    FactoryBot::SyntaxRunner.class_eval do
      def name
        'FactoryBot::SyntaxRunner'
      end
    end
    require 'rspec/core/minitest_assertions_adapter'
    FactoryBot::SyntaxRunner.include RSpec::Core::MinitestAssertionsAdapter
    # End of workarounds
    Hyrax::RedisEventStore.instance.then(&:flushdb)
    DatabaseCleaner.clean_with(:truncation)
    # Noid minting causes extra LDP requests which slow the test suite.
    Hyrax.config.enable_noids = false
    # setup a test group service
    User.group_service = TestHydraGroupService.new
    # Set a geonames username; doesn't need to be real.
    Hyrax.config.geonames_username = 'hyrax-test'
    # Initialize query_service class attribute by calling to avoid it sometimes being set to test_adapter
    Hyrax::SolrQueryService.query_service
    # disable analytics except for specs which will have proper api mocks
  end

  config.before :all do
    Hyrax.config.analytics = false
  end

  config.before do |example|
    if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end

    # using :workflow is preferable to :clean_repo, use the former if possible
    # It's important that this comes after DatabaseCleaner.start
    ensure_deposit_available_for(user) if example.metadata[:workflow] && defined?(user)
  end

  config.include(ControllerLevelHelpers, type: :view)

  config.before(:each, type: :view) do
    initialize_controller_helpers(view)

    allow(Hyrax)
      .to receive(:metadata_adapter)
      .and_return(Valkyrie::MetadataAdapter.find(:test_adapter))
  end

  config.before(:all, type: :feature) do
    # Assets take a long time to compile. This causes two problems:
    # 1) the profile will show the first feature test taking much longer than it
    #    normally would.
    # 2) The first feature test will trigger rack-timeout
    #
    # Precompile the assets to prevent these issues.
    visit "/assets/application.css"
    visit "/assets/application.js"
  end

  config.after do
    DatabaseCleaner.clean
    # Ensuring we have a clear queue between each spec.
    ActiveJob::Base.queue_adapter.enqueued_jobs  = []
    ActiveJob::Base.queue_adapter.performed_jobs = []
    User.group_service.clear
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.include Shoulda::Matchers::Independent

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include EngineRoutes, type: :controller
  config.include Warden::Test::Helpers, type: :request
  config.include Warden::Test::Helpers, type: :feature

  config.before(:each, type: :feature) do |example|
    adapter_name = example.metadata[:valkyrie_adapter]

    clean_active_fedora_repository unless
      # trust that clean_repo performed the clean if present
      example.metadata[:clean_repo] ||
      # don't run for adapters other than wings
      (adapter_name.present? && ![:wings_adapter, :freyja_adapter, :frigg_adapter].include?(adapter_name))
  end

  config.append_after(:each, type: :feature) do
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input
  config.include FactoryBot::Syntax::Methods
  config.include OptionalExample

  config.infer_spec_type_from_file_location!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.formatter = 'LoggingFormatter'
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_excluding(:active_fedora) if Hyrax.config.disable_wings
  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.profile_examples = 10

  # Should not be needed if filter_run_excluding(:active_fedora) above correctly avoids running context setup.
  # config.prepend_before(:context, :active_fedora) do
  #   skip("Don't test Wings") if Hyrax.config.disable_wings
  # end

  # Use this example metadata when you want to perform jobs inline during testing.
  #
  #   describe '#my_method`, :perform_enqueued do
  #     ...
  #   end
  #
  # If you pass an `Array` of job classes, they will be treated as the filter list.
  #
  #   describe '#my_method`, perform_enqueued: [MyJobClass] do
  #     ...
  #   end
  #
  # Limit to specific job classes with:
  #
  #   ActiveJob::Base.queue_adapter.filter = [JobClass]
  #
  config.around(:example, :perform_enqueued) do |example|
    ActiveJob::Base.queue_adapter.filter =
      example.metadata[:perform_enqueued].try(:to_a)
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter.filter = nil
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  config.before(:example, :index_adapter) do |example|
    allow(Hyrax.config)
      .to receive(:query_index_from_valkyrie)
      .and_return(true)

    adapter_name = example.metadata[:index_adapter]

    allow(Hyrax)
      .to receive(:index_adapter)
      .and_return(Valkyrie::IndexingAdapter.find(adapter_name))
  end

  config.before(:example, :clean_repo) do
    Hyrax.config.disable_wings ? Hyrax.persister.wipe! : clean_active_fedora_repository
    Hyrax::RedisEventStore.instance.then(&:flushdb)
    # Not needed to clean the Solr core used by ActiveFedora since
    # clean_active_fedora_repository will wipe that core
    Hyrax::SolrService.wipe! if Hyrax.config.query_index_from_valkyrie
  end

  config.after(:example, :index_adapter) do |example|
    adapter_name = example.metadata[:index_adapter]
    Valkyrie::IndexingAdapter.find(adapter_name).wipe!
  end

  # Configure blacklight to use the valkyrie solr index
  config.around(:example, index_adapter: :solr_index) do |example|
    blacklight_connection_url = CatalogController.blacklight_config.connection_config[:url]
    CatalogController.blacklight_config.connection_config[:url] = Valkyrie::IndexingAdapter.find(:solr_index).connection.options[:url]
    Blacklight.default_index.connection = nil # force reloading of rsolr connection
    example.run
    CatalogController.blacklight_config.connection_config[:url] = blacklight_connection_url
    Blacklight.default_index.connection = nil # force reloading of rsolr connection
  end

  # Prepend this before block to ensure that it runs before other before blocks like clean_repo
  config.prepend_before(:example, :valkyrie_adapter) do |example|
    adapter_name = example.metadata[:valkyrie_adapter]

    if [:wings_adapter, :freyja_adapter, :frigg_adapter].include?(adapter_name)
      skip("Don't test Wings when it is dasabled") if Hyrax.config.disable_wings
      unless adapter_name == :wings_adapter
        Valkyrie::StorageAdapter.register(
          Valkyrie::Storage::Disk.new(base_path: Rails.root.join("tmp", "storage", "files"),
                                      file_mover: FileUtils.method(:cp)),
          :disk
        )
        allow(Valkyrie.config)
          .to receive(:storage_adapter)
          .and_return(Valkyrie::StorageAdapter.find(:disk))
      end
    else
      allow(Hyrax.config).to receive(:disable_wings).and_return(true)
      hide_const("Wings") # disable_wings=true removes the Wings constant
    end

    allow(Hyrax)
      .to receive(:metadata_adapter)
      .and_return(Valkyrie::MetadataAdapter.find(adapter_name))
  end

  # Prepend this before block to ensure that it runs before other before blocks like clean_repo
  config.prepend_before(:example, :storage_adapter) do |example|
    adapter_name = example.metadata[:storage_adapter]

    allow(Hyrax)
      .to receive(:storage_adapter)
      .and_return(Valkyrie::StorageAdapter.find(adapter_name))
  end

  config.include RuboCop::RSpec::ExpectOffense
end
