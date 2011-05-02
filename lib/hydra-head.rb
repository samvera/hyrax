require "active-fedora"
require "solrizer"
require "solrizer-fedora"

module Hydra
  module Head
    # require 'hydra-head/engine' if defined?(Rails)
    require 'hydra-head/version' 
  end
end

module ActiveSupport::Dependencies::Loadable
  
  # Calls require_dependency with the given path
  # Provides a hook for intercepting calls to require_dependency that are referencing other plugins
  # @param [String] dependency_path path to the desired depencency
  def require_plugin_dependency(dependency_path)
    require_dependency dependency_path
  end
end

Dir[File.join(File.dirname(__FILE__), "hydra", "**", "*.rb")].each {|f| require f}
require "hydra"
require "stanford_blacklight_extensions"
require "blacklight"
Dir[File.join(File.dirname(__FILE__), "blacklight", "*.rb")].each {|f| require f}
Dir[File.join(File.dirname(__FILE__), "mediashelf", "*.rb")].each {|f| require f}
