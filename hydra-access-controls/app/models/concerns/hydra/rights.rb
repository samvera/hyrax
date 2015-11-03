module Hydra
  module Rights
    extend ActiveSupport::Concern
    included do
      # Rights
      property :rights, predicate: ::RDF::Vocab::DC.rights do |index|
        index.as :facetable
      end
      property :rightsHolder, predicate: ::RDF::URI('http://opaquenamespace.org/rights/rightsHolder') do |index|
        index.as :searchable, :facetable
      end
      property :copyrightClaimant, predicate: ::RDF::URI('http://id.loc.gov/vocabulary/relators/cpc')
    end
  end
end
