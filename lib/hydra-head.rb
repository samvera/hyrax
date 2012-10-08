module HydraHead 
  require 'hydra-core'
  require 'hydra-file-access'

  def self.version
    HydraHead::VERSION
  end

  def self.root
    @root ||= File.expand_path(File.dirname(File.dirname(__FILE__)))
  end
  
end
