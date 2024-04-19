# frozen_string_literal: true
source 'https://rubygems.org'

# Please see hyrax.gemspec for dependency information.
# Install gems from test app
if ENV['RAILS_ROOT']
  test_app_gemfile_path = File.expand_path('Gemfile', ENV['RAILS_ROOT'])
  eval_gemfile test_app_gemfile_path
else
  gemspec
end

group :development, :test do
  gem 'benchmark-ips'
  gem 'easy_translate'
  gem 'i18n-tasks'
  gem 'okcomputer'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'rspec'
  gem 'ruby-prof', require: false
  gem 'semaphore_test_boosters'
  gem "simplecov", require: false
end
