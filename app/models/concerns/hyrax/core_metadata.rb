# frozen_string_literal: true
module Hyrax
  # These are the metadata elements that Hyrax internally requires of
  # all managed Collections, Works and FileSets will have.
  module CoreMetadata
    extend ActiveSupport::Concern

    included do
      property :depositor, predicate: ::RDF::URI.new('http://id.loc.gov/vocabulary/relators/dpt'), multiple: false do |index|
        index.as :symbol, :stored_searchable
      end

      property :title, predicate: ::RDF::Vocab::DC.title do |index|
        index.as :stored_searchable, :facetable
      end

      def first_title
        title.first
      end

      # We reserve date_uploaded for the original creation date of the record.
      # For example, when migrating data from a fedora3 repo to fedora4,
      # fedora's system created date will reflect the date when the record
      # was created in fedora4, but the date_uploaded will preserve the
      # original creation date from the old repository.
      property :date_uploaded, predicate: ::RDF::Vocab::DC.dateSubmitted, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end

      property :date_modified, predicate: ::RDF::Vocab::DC.modified, multiple: false do |index|
        index.type :date
        index.as :stored_sortable
      end
    end
  end
end
