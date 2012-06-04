source 'http://rubygems.org'

gem 'rails', '~> 3.2.3'

gem 'sqlite3', '~> 1.3.6'
gem 'mysql2'
gem 'blacklight', '~> 3.4.2'
gem "hydra-head", :git => 'git://github.com/projecthydra/hydra-head.git',  :ref=>"25cb42c"
gem 'active-fedora', :git=>'git://github.com/projecthydra/active_fedora.git', :ref=>'c40b25c'
#gem 'hydra-head', '~> 4.0.1'
#gem 'active-fedora', :git => 'git://github.com/psu-stewardship/active_fedora.git' 
gem 'mailboxer', :git => 'git://github.com/psu-stewardship/mailboxer.git' 
gem 'execjs'
gem 'therubyracer'

# the :require arg is necessary on Linux-based hosts
gem 'rmagick', '~> 2.13.1', :require => 'RMagick'
gem 'devise', '~> 2.0.4'
gem 'delayed_job_active_record', '~> 0.3.2'
gem 'noid', '~> 0.5.5'
gem 'daemons'

gem 'hydra-ldap', '0.0.2'
gem 'zipruby'

group :assets do
  gem 'sass-rails',   "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'uglifier',     ">= 1.0.3"
  gem "compass-rails", "~> 1.0.0"
  gem "compass-susy-plugin", "~> 0.9.0"
end

group :integration do
  gem 'yaml_db', :git=>'git://github.com/lostapathy/yaml_db.git'
  gem 'passenger'
end

group :development, :test do
  gem 'unicorn-rails'
  gem "debugger"
  gem 'activerecord-import'
  gem "rails_indexes", :git => "https://github.com/warpc/rails_indexes"
  gem 'yaml_db', :git => 'git://github.com/lostapathy/yaml_db.git'
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
