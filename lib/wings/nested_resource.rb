# frozen_string_literal: true

module Wings
  class NestedResource < ActiveTriples::Resource
    include ::Hyrax::BasicMetadata
    property :title, predicate: ::RDF::Vocab::DC.title
    property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
    property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")

    def self.build_fragment_uri(uri)
      uri_id = uri.to_s.gsub('_:', '')
      ::RDF::URI("#nested_resource_#{uri_id}")
    end

    def initialize(uri = ::RDF::Node.new, _parent = ActiveTriples::Resource.new)
      uri = if uri.try(:node?)
              self.class.build_fragment_uri(uri)
            elsif uri.to_s.include?('#')
              ::RDF::URI(uri)
            end
      super
    end
  end
end
