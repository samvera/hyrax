require File.expand_path('../features/session_helpers', __FILE__)
require File.expand_path('../features/fixture_file_upload', __FILE__)

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :feature
  config.include Features::SessionHelpers, type: :feature
  config.include Features::FixtureFileUpload

  config.before(:each, type: :feature) do
    Warden.test_mode!
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end
