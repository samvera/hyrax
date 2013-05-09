module Hydra
  module BlacklightHelperBehavior
    include Blacklight::BlacklightHelperBehavior
    
    # Given a Fedora uri, generate a reasonable partial name
    # Rails thinks that periods indicate a filename, so escape them with slashes.
    # @param [Hash] document the solr document (hash of fields & values)
    # @return [String] the name for the display partial
    # @example
    #   document_partial_name('has_model_s' => ["info:fedora/hull-cModel:genericContent"])
    #    => "generic_content"
    #   document_partial_name('has_model_s' => ["info:fedora/hull-cModel:text.pdf"])
    #    => "text_pdf"
    def document_partial_name(document)
      display_type = document[blacklight_config.show.display_type]

      return 'default' unless display_type 

      Array(display_type).first.gsub(/^[^\/]+\/[^:]+:/,"").gsub(/\./, '_').underscore
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
