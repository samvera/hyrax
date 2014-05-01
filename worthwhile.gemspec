# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'worthwhile/version'

Gem::Specification.new do |spec|
  spec.name          = "worthwhile"
  spec.version       = Worthwhile::VERSION
  spec.authors       = ["Justin Coyne"]
  spec.email         = ["justin@curationexperts.com"]
  spec.summary       = %q{A simple institutional repository for Hydra}
  spec.description   = %q{A self-deposit system with works and and many attached files}
  spec.homepage      = ""
  spec.license       = "APACHE2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "engine_cart", "~> 0.3.4"
end
