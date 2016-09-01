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
  gem.license       = "APACHE-2.0"

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency 'activesupport', '>= 4', '< 6'
  gem.add_dependency "active-fedora", '>= 10.0.0', '< 12'
  gem.add_dependency 'cancancan', '~> 1.8'
  gem.add_dependency 'deprecation', '~> 1.0'
  gem.add_dependency "blacklight", '>= 5.16'
  gem.add_dependency "blacklight-access_controls", '~> 0.6'

  gem.add_development_dependency "rake", '~> 10.1'
  gem.add_development_dependency 'rspec', '~> 3.1'
end
