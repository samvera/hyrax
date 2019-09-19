# frozen_string_literal: true

ActiveFedora::Indexing::Map::IndexObject.class_eval do
  # This is to deprecate the following index configuration style:
  #   property :title, predicate: RDF::DC.title do |index|
  #     index.as :discoverable, :stored_searchable
  #   end
  #
  # in favor of:
  #   class MyWork < ActiveFedora::Base
  #     self.indexer = MyWorkIndexer
  #   end
  def as(*args)
    Deprecation.warn(self, "Index configuration for a property are deprecated and support will be removed from Hyrax 4.0. Write indexers to handle each property explicitly instead.")

    @term = args.last.is_a?(Hash) ? args.pop : {}
    @behaviors = args
  end
end
