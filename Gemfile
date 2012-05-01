source 'http://rubygems.org'

gem 'rails', '~> 3.2.3'

gem 'sqlite3', '~> 1.3.6'
gem 'mysql', '~> 2.8.1'
gem 'blacklight', '~> 3.3.2'
gem 'hydra-head', '~> 4.0.0'

gem 'devise', '~> 2.0.4'
gem 'delayed_job_active_record', '~> 0.3.2'
gem 'noid', '~> 0.5.5'

group :assets do
  gem "compass-rails", "~> 1.0.0"
  gem "compass-susy-plugin", "~> 0.9.0"
end

group :integration do
  gem 'yaml_db', :git=>'git://github.com/lostapathy/yaml_db.git'
  gem 'passenger'
end

group :development, :test do
  gem 'unicorn-rails'
  gem 'activerecord-import'
  gem "rails_indexes", :git => "https://github.com/warpc/rails_indexes"
  gem 'yaml_db', :git => 'git://github.com/lostapathy/yaml_db.git'
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'rspec-rails', '>= 2.4.0'
  gem 'debugger'
  gem 'ruby-prof'
  gem 'mocha'
  gem 'cucumber-rails', '~> 1.0', :require => false
  gem 'database_cleaner'
  gem 'capybara'
  gem 'bcrypt-ruby'
  gem "jettywrapper"
  gem "factory_girl_rails", "~> 1.7.0"
  gem 'launchy'
end # (leave this comment here to catch a stray line inserted by blacklight!)
