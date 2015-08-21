module CurationConcerns
  module BasicMetadata
    extend ActiveSupport::Concern

    included do
      property :label, predicate: ActiveFedora::RDF::Fcrepo::Model.downloadFilename, multiple: false

      property :depositor, predicate: ::RDF::URI.new('http://id.loc.gov/vocabulary/relators/dpt'), multiple: false do |index|
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
      property :title, predicate: ::RDF::DC.title do |index|
        index.as :stored_searchable, :facetable
      end
      property :creator, predicate: ::RDF::DC.creator do |index|
        index.as :stored_searchable, :facetable
      end
      property :contributor, predicate: ::RDF::DC.contributor do |index|
        index.as :stored_searchable, :facetable
      end
      property :description, predicate: ::RDF::DC.description do |index|
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

      # We reserve date_uploaded for the original creation date of the record.
      # For example, when migrating data from a fedora3 repo to fedora4,
      # fedora's system created date will reflect the date when the record
      # was created in fedora4, but the date_uploaded will preserve the
      # original creation date from the old repository.
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
    end
  end
end
