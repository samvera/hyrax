# Include hook code here
require "solrizer"
require "solrizer-fedora"

module ActiveSupport::Dependencies::Loadable
  # Provides a hook for intercepting calls to require_dependency that are referencing other plugins
  def require_plugin_dependency(dependency_path)
    modified_path = dependency_path
    p "requiring #{modified_path}"
    require_dependency modified_path
  end
end