# frozen_string_literal: true
source 'https://rubygems.org'

# Please see hyrax.gemspec for dependency information.
gemspec

group :development, :test do
  gem 'easy_translate'
  gem 'i18n-tasks'
  gem 'okcomputer'
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem "simplecov", require: false
  gem 'benchmark-ips'
  gem 'ruby-prof', require: false
end

test_app_path    = ENV['RAILS_ROOT'] ||
                   ENV.fetch('ENGINE_CART_DESTINATION', File.expand_path('.internal_test_app', File.dirname(__FILE__)))
test_app_gemfile = File.expand_path('Gemfile', test_app_path)

if File.exist?(test_app_gemfile)
  begin
    eval_gemfile test_app_gemfile
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[Hyrax] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[Hyrax] Unable to find test application dependencies in #{test_app_gemfile}, using placeholder dependencies"

  # rubocop:disable Bundler/DuplicatedGem
  if ENV['RAILS_VERSION']
    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end
  end
  # rubocop:enable Bundler/DuplicatedGem

  eval_gemfile File.expand_path('spec/test_app_templates/Gemfile.extra', File.dirname(__FILE__))
end
