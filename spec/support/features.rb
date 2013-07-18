# spec/support/features.rb
require File.expand_path('../features/session_helpers', __FILE__)

RSpec.configure do |config|
  config.include Features::SessionHelpers, type: :feature
end
