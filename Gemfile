source 'https://rubygems.org'

# Please see sufia.gemspec for dependency information.
gemspec


# Required for doing pagination inside an engine. See https://github.com/amatsuda/kaminari/pull/322
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'
gem 'sufia-models', path: './sufia-models'
gem 'sass-rails', '~> 4.0.0'

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails', '~> 3.0.1'
  gem 'rspec-its'
  gem 'launchy' unless ENV['TRAVIS']
  gem 'byebug' unless ENV['TRAVIS']
  gem 'capybara', '~> 2.3.0'
  gem 'poltergeist'
  gem "jettywrapper"
  gem "factory_girl_rails"
  gem "devise"
  gem 'jquery-rails'
  gem 'turbolinks'
  gem "bootstrap-sass"
  gem "simplecov", :require => false
  gem "spring"
  gem 'database_cleaner'
end # (leave this comment here to catch a stray line inserted by blacklight!)
