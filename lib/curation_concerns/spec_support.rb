# Given that curate provides custom matchers, factories, etc.
# When someone makes use of curate in their Rails application
# Then we should expose those spec support files to that applications
spec_directory = File.expand_path('../../../spec', __FILE__)

# Dir["#{spec_directory}/factories/**/*.rb"].each { |f| require f }
Dir["#{spec_directory}/support/curation_concern/*.rb"].each { |f| require f }
Dir["#{spec_directory}/support/shared/*.rb"].each { |f| require f }


