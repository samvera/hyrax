require 'rdf'

# hints:
#   https://github.com/mediashelf/om/blob/master/lib/om/xml/document.rb
#   https://github.com/mediashelf/om/blob/master/lib/om/xml/terminology.rb

module RDFDatastreamMethods
  attr :vocabularies
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    attr_accessor :vocabularies
    def register_vocabularies(*vocabs)
      # TODO: check if each vocab is either an RDF::Vocabulary or an RDF::URI
      @vocabularies = vocabs
    end
    def map_predicates(&block)
      # TODO: check if each predicate is defined within the specified vocab
      #       e.g.: RDF::DC.send(name) if RDF::DC.respond_to? name
      yield self
    end
  end
end
class DummyRDFDatastream
  include RDFDatastreamMethods
  register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
  map_predicates do |element|
    element.title(RDF::DC.title)
    element.name(RDF::FOAF.name)
    element.url(RDF::RDFS.seeAlso)
  end
end
d = DummyRDFDatastream.new

