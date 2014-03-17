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
      display_type = document[blacklight_config.show.display_type_field]

      return 'default' unless display_type 

      Array(display_type).first.gsub(/^[^\/]+\/[^:]+:/,"").gsub(/\./, '_').underscore
    end    
  end
end
