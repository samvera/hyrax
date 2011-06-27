module HydraHead 
  require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  require 'application_controller'

  require 'hydra-head/version'

  def self.version
    HydraHead::VERSION
  end

  def self.root
    @root ||= File.expand_path(File.dirname(File.dirname(__FILE__)))
  end
  
end