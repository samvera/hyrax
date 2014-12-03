# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../../HYDRA_VERSION", __FILE__)).strip

Gem::Specification.new do |gem|
  gem.authors       = ["Chris Beer", "Justin Coyne", "Matt Zumwalt"]
  gem.email         = ["hydra-tech@googlegroups.com"]
  gem.description   = %q{Access controls for project hydra}
  gem.summary       = %q{Access controls for project hydra}
  gem.homepage      = "http://projecthydra.org"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "hydra-access-controls"
  gem.require_paths = ["lib"]
  gem.version       = version
  gem.license       = "APACHE2"

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency 'activesupport'
  gem.add_dependency "active-fedora", '~> 9.0.0.beta3'
  gem.add_dependency 'cancancan'
  gem.add_dependency 'deprecation'
  gem.add_dependency "blacklight", '~> 5.3'

  # sass-rails is typically generated into the app's gemfile by `rails new`
  # In rails 3 it's put into the "assets" group and thus not available to the
  # app. Blacklight 5.3 requires bootstrap-sass which requires (but does not
  # declare a dependency on) sass-rails
  gem.add_dependency 'sass-rails'

  gem.add_development_dependency "rake"
  gem.add_development_dependency 'rspec'
end
