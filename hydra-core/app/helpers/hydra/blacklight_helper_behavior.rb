module Hydra
  module BlacklightHelperBehavior
    include Blacklight::BlacklightHelperBehavior
    
    ##
    # Given a Fedora uri, generate a reasonable partial name
    # Rails thinks that periods indicate a filename, so escape them with slashes.
    #
    # @param [SolrDocument] document
    # @param [String, Array] display_type a value suggestive of a partial
    # @return [String] the name of the partial to render
    # @example
    #   type_field_to_partial_name(["info:fedora/hull-cModel:genericContent"])
    #   => 'generic_content'
    #   type_field_to_partial_name(["info:fedora/hull-cModel:text.pdf"])
    #   => 'text_pdf'
    def type_field_to_partial_name(document, display_type)
      Array(display_type).first.gsub(/^[^\/]+\/[^:]+:/,"").gsub("-","_").underscore.parameterize("_")
    end
  end
end
