require "worthwhile/version"
require 'worthwhile/engine'
require 'worthwhile/configuration'

module Worthwhile
  # TODO move this into a generated initialize or something.
  configuration.register_curation_concern 'GenericWork'
end
