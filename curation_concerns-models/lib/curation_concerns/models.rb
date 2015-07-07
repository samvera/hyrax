require "curation_concerns/models/version"
require "curation_concerns/models/engine"
require "curation_concerns/models/virus_found_error"
module CurationConcerns
  module Models
  end

  # Proxy CurationConcerns.config to CurationConcerns::Models::Engine::Configuration
  def self.config(&block)
    @@config ||= CurationConcerns::Models::Engine::Configuration.new

    yield @@config if block

    return @@config
  end
end

