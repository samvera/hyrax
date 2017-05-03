#!/usr/bin/env rake
# frozen_string_literal: true

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

import "#{Gem.loaded_specs['jasmine'].full_gem_path}/lib/jasmine/tasks/jasmine.rake"

# Set up the test application prior to running jasmine tasks.
task 'jasmine:require' => :setup_test_server
task :setup_test_server do
  require 'engine_cart'
  EngineCart.load_application!
end

Dir.glob('tasks/*.rake').each { |r| import r }

task default: :ci
