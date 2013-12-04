source 'https://rubygems.org'

# Please see sufia.gemspec for dependency information.
gemspec

# Required for doing pagination inside an engine. See https://github.com/amatsuda/kaminari/pull/322
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'
gem 'sufia-models', path: './sufia-models'

group :development, :test do
  gem 'sqlite3'
  gem 'selenium-webdriver'
  gem 'rspec-rails'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
  gem "jettywrapper"
  gem "factory_girl_rails"
  gem "devise"
  gem 'jquery-rails'
  gem 'sass-rails'
  gem 'turbolinks'
  gem "bootstrap-sass"
  gem "simplecov", :require => false
end # (leave this comment here to catch a stray line inserted by blacklight!)
