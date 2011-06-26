module HydraHead 
  require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  require 'application_controller'

  require 'hydra-head/version'

  def self.version
    HydraHead::VERSION
  end
end
