module CurationConcerns
  module RequiredMetadata
    extend ActiveSupport::Concern

    included do
      property :depositor, predicate: ::RDF::URI.new('http://id.loc.gov/vocabulary/relators/dpt'), multiple: false do |index|
        index.as :symbol, :stored_searchable
      end
      property :title, predicate: ::RDF::Vocab::DC.title do |index|
        index.as :stored_searchable, :facetable
      end
    end
  end
end
