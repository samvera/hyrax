unless defined?(Rails)
  # Load Rails from the test app!
  ENV["RAILS_ROOT"] = File.expand_path("../../.dassie", __FILE__)
  require File.expand_path("../../.dassie/config/environment", __FILE__)
end

Teaspoon.configure do |config|
  config.root = Hyrax::Engine.root
  config.suite do |suite|
    suite.use_framework :jasmine, "2.9.1"
  end
end