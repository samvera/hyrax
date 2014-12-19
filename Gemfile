source 'https://rubygems.org'

gem 'hydra-head', github:"projecthydra/hydra-head", branch:'master'
gem 'active-fedora', github:"projecthydra/active_fedora", ref:'a4b4d5e0e4e3342ce5a2a9b337ee744cecd68cc5'

# Specify your gem's dependencies in worthwhile.gemspec
gemspec

gem 'byebug' unless ENV['TRAVIS']
gem 'sass-rails', '~> 4.0.3'
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
end
