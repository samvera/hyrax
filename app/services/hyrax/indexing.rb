module Hyrax
  # Mix in this module to update Solr on save.
  # Assign a new indexer at the class level where this is mixed in
  #   (or define an #indexing_service method)
  #   to change the document contents sent to solr
  #
  # Example indexing services are:
  # @see ActiveFedora::IndexingService
  # @see ActiveFedora::RDF::IndexingService
  module Indexing
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload

    class InvalidIndexDescriptor < RuntimeError; end
    class UnknownIndexMacro < StandardError; end

    eager_autoload do
      autoload :Suffix
      autoload :Descriptor
      autoload :StringDescriptor
      autoload :DefaultDescriptors
      autoload :FieldMapper
      autoload :Solr
    end
  end
end
