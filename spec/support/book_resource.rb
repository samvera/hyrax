# frozen_string_literal: true
module Hyrax
  module Test
    ##
    # A simple Hyrax::Resource with some metadata.
    #
    # Use this for testing valkyrie models generically, with Hyrax assumptions
    # but no PCDM modelling behavior.
    class BookResource < Hyrax::Resource
      attribute :author,    Valkyrie::Types::String
      attribute :created,   Valkyrie::Types::Date
      attribute :isbn,      Valkyrie::Types::String
      attribute :publisher, Valkyrie::Types::String
      attribute :title,     Valkyrie::Types::String
    end

    ##
    # A simple Hyrax::ChangeSet with one custom validation.
    #
    # Hyrax::Test::BookResource will use this based on naming convention by adding `ChangeSet`
    # to the end of the resource class name.
    class BookResourceChangeSet < Hyrax::ChangeSet
      validates :isbn, presence: true
    end

    class Book < ActiveFedora::Base
      property :author,    predicate: ::RDF::URI('http://example.com/ns/author')
      property :created,   predicate: ::RDF::URI('http://example.com/ns/created')
      property :isbn,      predicate: ::RDF::URI('http://example.com/ns/isbn')
      property :publisher, predicate: ::RDF::URI('http://example.com/ns/publisher')
      property :title,     predicate: ::RDF::URI("http://example.com/ns/title")
    end
  end
end

Wings::ModelRegistry.register(Hyrax::Test::BookResource, Hyrax::Test::Book) if defined?(Wings)
