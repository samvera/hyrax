# coding: utf-8
version = File.read(File.expand_path("../../WORTHWHILE_VERSION", __FILE__)).strip

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "worthwhile-models"
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

  # spec.add_dependency 'hydra-head', "~> 9.0.0.beta1"
  # spec.add_dependency "active-fedora", "~> 9.0.0.beta5"
  spec.add_dependency "active_attr"
  spec.add_dependency 'sufia-models', '~> 6.0.0'
  spec.add_dependency 'active_fedora-noid'
  spec.add_dependency 'hydra-collections'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
