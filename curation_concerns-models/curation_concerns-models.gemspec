# coding: utf-8
version = File.read(File.expand_path("../../VERSION", __FILE__)).strip

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "curation_concerns-models"
  spec.version       = version
  spec.authors       = ["Justin Coyne"]
  spec.email         = ["justin@curationexperts.com"]
  spec.summary       = %q{Simple institutional repository models for Hydra}
  spec.description   = %q{An extensible repository data-model with works and and many attached files}
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'active_attr'
  spec.add_dependency 'hydra-collections', '~> 7.0'
  spec.add_dependency 'hydra-head', '~> 9.3'
  spec.add_dependency 'hydra-works', '~> 0.7'
  spec.add_dependency 'active_fedora-noid', '~> 1.0'
  spec.add_dependency 'resque', '~> 1.23'
  spec.add_dependency 'resque-pool', '~> 0.3'
  spec.add_dependency 'qa', '~> 0.5'
  spec.add_dependency 'redlock', '~> 0.1.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
