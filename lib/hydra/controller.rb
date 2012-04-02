module Hydra::Controller
  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::AccessControlsEnforcement)
    #klass.send(:include, MediaShelf::ActiveFedoraHelper)
    klass.send(:include, Hydra::RepositoryController)
  
  
    # Controller filters
    # Also see the generator (or generated CatalogController) to see more before_filters in action
    #klass.before_filter :require_solr, :check_scripts
    # klass.before_filter :load_fedora_document, :only=>[:show,:edit]
  
    # View Helpers
    klass.helper :hydra
    klass.helper :hydra_assets
    klass.helper :hydra_uploader
    klass.helper :article_metadata
  end
  
  def check_scripts
    session[:scripts] ||= (params[:combined] and params[:combined] == "true")
  end
  
  def user_key
    current_user.send(Devise.authentication_keys.first)
  end
  
end
