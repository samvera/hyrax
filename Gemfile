source 'https://rubygems.org'

# Please see hyrax.gemspec for dependency information.
gemspec

group :development, :test do
  gem 'coveralls', require: false
  gem 'pry' unless ENV['CI']
  gem 'pry-byebug' unless ENV['CI']
  gem "simplecov", require: false
end

unless File.exist?(file)
  eval_gemfile File.expand_path('spec/test_app_templates/Gemfile.extra', File.dirname(__FILE__))
end

