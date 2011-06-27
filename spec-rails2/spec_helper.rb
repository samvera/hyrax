# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'

# Overrides require_plugin_dependency, pointing to plugins within dummy app
# Original require_plugin_dependency method defined in init.rb
def require_plugin_dependency(dependency_path)
  modified_path = File.join(File.dirname(__FILE__), "..","hydra-plugin_test_host", dependency_path)
  p "(spec_helper) Re-routing require path to: #{modified_path}"
  require_dependency modified_path
end

require File.dirname(__FILE__) + "/../hydra-plugin_test_host/config/environment" unless defined?(RAILS_ROOT)

# This ensures that the current plugin's models, helpers and controllers are loaded last
# Dir["app/helpers/*.rb"].each {|f| require f }
# Dir["app/models/*.rb"].each {|f| require f}
# Dir["app/controllers/*.rb"].each {|f| require f} # Loading the controllers a second time messes up the method aliasing for CatalogController.show

require 'spec/autorun'
require 'spec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each {|f| require f}

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  #
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
  
  def fixture(file)
    File.new(File.join(File.dirname(__FILE__), 'fixtures', file))
  end
  
  def match_html(html)
    # Match two strings, but don't care about whitespace
    simple_matcher("should match #{html}"){|given| given.strip.gsub(/\s+/,' ').gsub('> <','><') == html.strip.gsub(/\s+/,' ').gsub('> <','><') }
  end
  
  def connect_bl_solr
    # @connection = Solr::Connection.new( SHELVER_SOLR_URL, :autocommit => :on )
    if defined?(@index_full_text) && @index_full_text
      url = Blacklight.solr_config['fulltext']['url']
    else
      url = Blacklight.solr_config[:url]
    end
  
    @bl_solr = Solr::Connection.new(url, :autocommit => :on )
  end
  
end
