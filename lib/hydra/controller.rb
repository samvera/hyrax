# Adds behaviors that Hydra needs all controllers to have. (mostly view helpers and access controls)
module Hydra::Controller

  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::AccessControlsEnforcement)
    klass.send(:include, MediaShelf::ActiveFedoraHelper)
    klass.send(:include, Hydra::RepositoryController)
  
  
    # Controller filters
    # Also see the generator (or generated CatalogController) to see more before_filters in action
    klass.before_filter :require_solr
    # klass.before_filter :load_fedora_document, :only=>[:show,:edit]
  
    # View Helpers
    klass.helper :hydra
    klass.helper :hydra_assets
  end
  
  def user_key
    current_user.send(Devise.authentication_keys.first)
  end
  
end
