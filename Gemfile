source 'https://rubygems.org'

# Please see hyrax.gemspec for dependency information.
gemspec

group :development, :test do
  gem 'coveralls', require: false
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem "simplecov", require: false
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
end

