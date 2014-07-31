source 'https://rubygems.org'

# Specify your gem's dependencies in worthwhile.gemspec
gemspec

gem 'byebug' unless ENV['TRAVIS']
gem 'sass-rails', '~> 4.0.3'
# TODO: Ditch this once https://github.com/projectblacklight/blacklight/issues/956 is merged
gem 'blacklight', '5.5.1'
gem 'sufia-models', github: 'projecthydra/sufia'

group :test do
  # Peg simplecov to < 0.8 until this is resolved:
  # https://github.com/colszowka/simplecov/issues/281
  gem 'simplecov', '~> 0.7.1', require: false
  gem 'poltergeist'
end

file = File.expand_path("Gemfile", ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path("../spec/internal", __FILE__))
if File.exists?(file)
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
end
