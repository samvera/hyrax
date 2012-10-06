module HydraHead 
  #require 'hydra-access-controls'
  require 'hydra-core'
  require 'hydra-file-access'
  
  def self.version
    HydraHead::VERSION
  end

  def self.root
    @root ||= File.expand_path(File.dirname(File.dirname(__FILE__)))
  end
  
  # If you put this in your application's routes.rb, it will add the Hydra Head routes to the app.
  # The hydra:head generator puts this in routes.rb for you by default.
  # See {HydraHead::Routes} for information about how to modify which routes are generated.
  # @example 
  #   # in config/routes.rb
  #   MyAppName::Application.routes.draw do
  #     Blacklight.add_routes(self)
  #     HydraHead.add_routes(self)
  #   end
  def self.add_routes(router, options = {})
    HydraHead::Routes.new(router, options).draw
  end
  
end
