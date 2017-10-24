module Hyrax
  class LinkedDataResourceFactory
    # Instantiate a LinkedDataResources class
    #
    # @param ld_attribute [Symbol] attribute used to define LinkedDataResources Class
    # @param ld_uri [RDF::URI] uri from which to retrieve a label
    # @return [Hyrax::LinkedDataResources::BaseResource] or more speciic class
    def self.for(ld_attribute, ld_uri)
      Hyrax.config.registered_linked_data_resources.fetch(ld_attribute, Hyrax::LinkedDataResources::BaseResource).new(ld_uri)
    end
  end
end
