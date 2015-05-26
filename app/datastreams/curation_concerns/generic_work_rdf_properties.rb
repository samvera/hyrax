module CurationConcerns::GenericWorkRdfProperties
  extend ActiveSupport::Concern
  included do
    property :part_of, predicate: RDF::DC.isPartOf
    property :resource_type, predicate: RDF::DC.type do |index|
      index.as :stored_searchable, :facetable
    end
    property :title, predicate: RDF::DC.title do |index|
      index.as :stored_searchable, :facetable
    end
    property :creator, predicate: RDF::DC.creator do |index|
      index.as :stored_searchable, :facetable
    end
    property :contributor, predicate: RDF::DC.contributor do |index|
      index.as :stored_searchable, :facetable
    end
    property :description, predicate: RDF::DC.description do |index|
      index.type :text
      index.as :stored_searchable
    end
    property :relation, predicate: RDF::DC.relation
    property :rights, predicate: RDF::DC.rights do |index|
      index.as :stored_searchable
    end
    property :publisher, predicate: RDF::DC.publisher do |index|
      index.as :stored_searchable, :facetable
    end
    property :created, predicate: RDF::DC.created

    property :date, predicate: RDF::DC.date do |index|
      index.type :date
      index.as :stored_sortable
    end
    property :date_uploaded, predicate: RDF::DC.dateSubmitted do |index|
      index.type :date
      index.as :stored_sortable
    end
    property :date_modified, predicate: RDF::DC.modified do |index|
      index.type :date
      index.as :stored_sortable
    end
    property :subject, predicate: RDF::DC.subject do |index|
      index.as :stored_searchable, :facetable
    end
    property :language, predicate: RDF::DC.language do |index|
      index.as :stored_searchable, :facetable
    end
    property :identifier, predicate: RDF::DC.identifier do |index|
      index.as :stored_searchable
    end
    property :bibliographic_citation, predicate: RDF::DC.bibliographicCitation
    property :source, predicate: RDF::DC.source
    property :coverage, predicate: RDF::DC.coverage
    property :type, predicate: RDF::DC.type
    property :content_format, predicate: RDF::DC.format
  end
end
