source 'http://rubygems.org'

gem 'rails', '3.2.3'

gem 'sqlite3', '1.3.6'
gem 'mysql2', '0.3.11'
gem 'blacklight', '3.4.2'
gem 'hydra-head', '4.0.3'
gem 'active-fedora', '4.2.0'
gem 'hydra-ldap', '0.0.2'

# the :require arg is necessary on Linux-based hosts
gem 'rmagick', '2.13.1', :require => 'RMagick'
gem 'devise', '2.0.4'
gem 'delayed_job_active_record', '0.3.2'
gem 'noid', '0.5.5'
gem 'daemons', '1.1.8'
gem 'execjs', '1.4.0'
gem 'therubyracer', '0.10.1'
gem 'zipruby', '0.3.6'
gem 'yaml_db', :git => 'git://github.com/lostapathy/yaml_db.git'
gem 'mailboxer', :git => 'git://github.com/psu-stewardship/mailboxer.git'

group :assets do
  gem 'sass-rails', "3.2.5"
  gem 'coffee-rails', "3.2.2"
  gem 'uglifier', "1.2.4"
  gem "compass-rails", "1.0.1"
  gem "compass-susy-plugin", "0.9.0"
end

group :production, :integration do
  gem 'passenger'
end

group :development, :test do
  gem 'unicorn-rails'
  gem "debugger"
  gem 'activerecord-import'
  gem "rails_indexes", :git => "https://github.com/warpc/rails_indexes"
  gem 'selenium-webdriver'
  gem 'headless'
  gem 'rspec', '2.10.0'
  gem 'rspec-rails', '>= 2.4.0'
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
