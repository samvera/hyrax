module CurationConcern
  # This is a direct copy of Sufia::GenericFile::Metadata with a few modifications:
  # * title & description are single-value instead of multivalue
  module WithBasicMetadata
    extend ActiveSupport::Concern

    included do

      property :label, predicate: ::RDF::DC.title, multiple: false

      property :depositor, predicate: ::RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt"), multiple: false do |index|
        index.as :symbol, :stored_searchable
      end

      property :relative_path, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#relativePath'), multiple: false

      property :import_url, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#importUrl'), multiple: false do |index|
        index.as :symbol
      end

      property :part_of, predicate: ::RDF::DC.isPartOf
      property :resource_type, predicate: ::RDF::DC.type do |index|
        index.as :stored_searchable, :facetable
      end
      property :title, predicate: ::RDF::DC.title, multiple:false do |index|
        index.as :stored_searchable, :facetable
      end
      property :creator, predicate: ::RDF::DC.creator do |index|
        index.as :stored_searchable, :facetable
      end
      property :contributor, predicate: ::RDF::DC.contributor do |index|
        index.as :stored_searchable, :facetable
      end
      property :description, predicate: ::RDF::DC.description, multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end
      property :tag, predicate: ::RDF::DC.relation do |index|
        index.as :stored_searchable, :facetable
      end
      property :rights, predicate: ::RDF::DC.rights do |index|
        index.as :stored_searchable
      end
      property :publisher, predicate: ::RDF::DC.publisher do |index|
        index.as :stored_searchable, :facetable
      end
      property :date_created, predicate: ::RDF::DC.created do |index|
        index.as :stored_searchable
      end
      property :date_uploaded, predicate: ::RDF::DC.dateSubmitted, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end
      property :date_modified, predicate: ::RDF::DC.modified, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end
      property :subject, predicate: ::RDF::DC.subject do |index|
        index.as :stored_searchable, :facetable
      end
      property :language, predicate: ::RDF::DC.language do |index|
        index.as :stored_searchable, :facetable
      end
      property :identifier, predicate: ::RDF::DC.identifier do |index|
        index.as :stored_searchable
      end
      property :based_near, predicate: ::RDF::FOAF.based_near do |index|
        index.as :stored_searchable, :facetable
      end
      property :related_url, predicate: ::RDF::RDFS.seeAlso do |index|
        index.as :stored_searchable
      end
      property :bibliographic_citation, predicate: ::RDF::DC.bibliographicCitation do |index|
        index.as :stored_searchable
      end
      property :source, predicate: ::RDF::DC.source do |index|
        index.as :stored_searchable
      end

      # TODO: Move this somewhere more appropriate
      begin
        LocalAuthority.register_vocabulary(self, "subject", "lc_subjects")
        LocalAuthority.register_vocabulary(self, "language", "lexvo_languages")
        LocalAuthority.register_vocabulary(self, "tag", "lc_genres")
      rescue
        puts "tables for vocabularies missing"
      end
    end

    # Add a schema.org itemtype
    def itemtype
      # Look up the first non-empty resource type value in a hash from the config
      Sufia.config.resource_types_to_schema[resource_type.to_a.reject { |type| type.empty? }.first] || 'http://schema.org/CreativeWork'
    rescue
      'http://schema.org/CreativeWork'
    end
  end
end
