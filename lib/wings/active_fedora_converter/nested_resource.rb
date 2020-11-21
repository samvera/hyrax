# frozen_string_literal: true

module Wings
  class ActiveFedoraConverter
    class NestedResource < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC.title
      property :author, predicate: ::RDF::URI('http://example.com/ns/author')
      property :depositor, predicate: ::RDF::URI('http://example.com/ns/depositor')
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: NestedResource
      property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
      property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")

      def initialize(uri = RDF::Node.new, _parent = ActiveTriples::Resource.new)
        uri = if uri.try(:node?)
                RDF::URI("#nested_resource_#{uri.to_s.gsub('_:', '')}")
              elsif uri.to_s.include?('#')
                RDF::URI(uri)
              end
        super
      end

      include ::Hyrax::BasicMetadata
    end
  end
end
