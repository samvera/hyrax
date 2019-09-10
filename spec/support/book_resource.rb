# frozen_string_literal: true
module Hyrax
  module Test
    class BookResource < Hyrax::Resource
      attribute :author,   Valkyrie::Types::String
      attribute :created,  Valkyrie::Types::Date
      attribute :isbn,     Valkyrie::Types::String
      attribute :pubisher, Valkyrie::Types::String
      attribute :title,    Valkyrie::Types::String
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

Wings::ModelRegistry.register(Hyrax::Test::BookResource, Hyrax::Test::Book)
