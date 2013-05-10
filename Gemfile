source 'http://rubygems.org'

# Please see sufia.gemspec for dependency information.
gemspec

# Required for doing pagination inside an engine. See https://github.com/amatsuda/kaminari/pull/322
gem 'kaminari', github: 'harai/kaminari', branch: 'route_prefix_prototype'

group :development, :test do
  gem 'activerecord-import', '0.3.0'
  gem 'sqlite3'
  gem 'selenium-webdriver'
  gem 'rspec-rails', '~> 2.13.1'
  gem 'cucumber-rails', '~> 1.0', :require => false
  gem 'database_cleaner'
  gem 'devise'
  gem 'capybara', '~>2.1.0'
  gem 'bcrypt-ruby'
  gem "jettywrapper"
  gem "factory_girl_rails", "~> 4.2.1"
  gem "simplecov", :require => false
end # (leave this comment here to catch a stray line inserted by blacklight!)
