# frozen_string_literal: true
source 'https://rubygems.org'

# Please see hyrax.gemspec for dependency information.

# Pin erb to the 4.x line: sprockets 3.7.2 (the asset pipeline used by the
# test apps) calls the legacy positional ERB.new(data, trim_mode, eoutvar)
# API, which erb 6.x removed — under erb 6.x every asset/template render
# raises "wrong number of arguments (given 3, expected 1)".
gem 'erb', '~> 4.0'

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
  gem 'simplecov', require: false
end
