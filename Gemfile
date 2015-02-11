source 'https://rubygems.org'

# Specify your gem's dependencies in worthwhile.gemspec
gemspec

gem 'byebug' unless ENV['TRAVIS']
gem 'worthwhile-models', path: './worthwhile-models'

group :test do
  gem 'simplecov', '~> 0.9', require: false
  gem 'coveralls', require: false
  gem 'poltergeist'
end

file = File.expand_path("Gemfile", ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path("../spec/internal", __FILE__))
if File.exists?(file)
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
else
  gem 'rails', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

  if ENV['RAILS_VERSION'] and ENV['RAILS_VERSION'] !~ /^4.2/
    gem 'sass-rails', "< 5.0"
  else
    gem 'responders', "~> 2.0"
    gem 'sass-rails', ">= 5.0"
  end
end
