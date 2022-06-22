#!/usr/bin/env rake
# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

task :setup_test_server do
  require 'engine_cart'
  EngineCart.load_application!
end

Dir.glob('tasks/*.rake').each { |r| import r }

task default: :ci

# Load the test app's rake tasks so they can be run from the app namespace (e.g. app:db:migrate)
if File.exist?(File.expand_path(".internal_test_app/Rakefile", __dir__))
  APP_RAKEFILE = File.expand_path(".internal_test_app/Rakefile", __dir__)
  load 'rails/tasks/engine.rake'
end
