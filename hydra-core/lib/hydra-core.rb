require 'hydra-access-controls'
require 'deprecation'

module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
end

module HydraHead 
  extend Deprecation
  require 'hydra-head/engine' if defined?(Rails)
  def self.add_routes(router, options = {})
    Deprecation.warn HydraHead, "add_routes has been removed." # remove this warning in hydra-head 8
  end
end

