# frozen_string_literal: true
source 'https://rubygems.org'
# Please see hyrax.gemspec for dependency information.
gemspec

group :development, :test do
  gem 'benchmark-ips'
  gem 'easy_translate'
  gem 'i18n-tasks'
  gem 'okcomputer'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem 'ruby-prof', require: false
  gem "simplecov", require: false
end
# TODO Rob remove after valk merge
gem 'valkyrie', github: 'samvera/valkyrie', branch: 'more_flexible_shared_query_spec'

# Install gems from test app
if ENV['RAILS_ROOT']
  test_app_gemfile_path = File.expand_path('Gemfile', ENV['RAILS_ROOT'])
  eval_gemfile test_app_gemfile_path
end
