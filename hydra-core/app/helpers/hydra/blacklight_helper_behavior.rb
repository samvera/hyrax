module Hydra
  module BlacklightHelperBehavior
    include Blacklight::BlacklightHelperBehavior
    
    # Given a Fedora uri, generate a reasonable partial name
    def document_partial_name(document)
      display_type = document[blacklight_config.show.display_type]

      return 'default' unless display_type 

      display_type.first.gsub(/^[^\/]+\/[^:]+:/,"").underscore
    end    

  #   COPIED from vendor/plugins/blacklight/app/helpers/application_helper.rb
    # Used in catalog/facet action, facets.rb view, for a click
    # on a facet value. Add on the facet params to existing
    # search constraints. Remove any paginator-specific request
    # params, or other request params that should be removed
    # for a 'fresh' display. 
    # Change the action to 'index' to send them back to
    # catalog/index with their new facet choice. 
    def add_facet_params_and_redirect(field, value)
      new_params = super

      # Delete :qt, if needed - added to resolve NPE errors
      new_params.delete(:qt)

      new_params
    end

  end
end
