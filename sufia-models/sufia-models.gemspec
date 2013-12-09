# coding: utf-8
version = File.read(File.expand_path("../../SUFIA_VERSION", __FILE__)).strip


Gem::Specification.new do |spec|
  spec.name          = "sufia-models"
  spec.version       = version 
  spec.authors       = [
    "Jeremy Friesen",
  ]
  spec.email         = [
    "jeremy.n.friesen@gmail.com",
  ]
  spec.description   = %q{Models and services for sufia}
  spec.summary       = %q{Models and services for sufia}

  # This is a temporary homepage until we've had a chance to review the
  # process
  spec.homepage      = "https://github.com/projecthydra/sufia"
  spec.license       = "Apache"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency 'rails', '> 4.0.0', '< 5.0'
  spec.add_dependency 'activeresource' # No longer a dependency of rails 4.0

  # spec.add_dependency "hydra", "6.1.0.rc2"
  # Since hydra 6.1 isn't out yet, we'll just build it so that it's compatible 
  # without an explicit dependency
  spec.add_dependency "active-fedora", "~> 6.7.0"
  spec.add_dependency "blacklight", "~> 4.5.0"
  spec.add_dependency "hydra-head", "~> 6.4.0"

  spec.add_dependency 'nest', '~> 1.1.1'
  spec.add_dependency 'resque', '~> 1.23'
  spec.add_dependency 'resque-pool', '0.3.0'
  spec.add_dependency 'noid', '~> 0.6.6'
  spec.add_dependency 'mailboxer', '~> 0.11.0'
  spec.add_dependency 'acts_as_follower', '>= 0.1.1', '< 0.3'
  spec.add_dependency 'paperclip', '~> 3.4.0'
  spec.add_dependency 'zipruby', '0.3.6'
  spec.add_dependency 'hydra-derivatives', '~> 0.0.5'
  spec.add_dependency 'activerecord-import'
end
