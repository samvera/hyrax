class GammaRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  include ActiveFedora::RDFDatastream::ModelMethods
  register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
  map_predicates do |map|
    map.part_of(:to => "isPartOf", :in => RDF::DC)
    map.contributor(:to => "contributor", :in => RDF::DC)
    map.creator(:to => "creator", :in => RDF::DC)
    map.title(:to => "title", :in => RDF::DC)
    map.description(:to => "description", :in => RDF::DC)
    map.publisher(:to => "publisher", :in => RDF::DC)
    map.date_created(:to => "created", :in => RDF::DC)
    map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC)
    map.date_modified(:to => "modified", :in => RDF::DC)
    map.subject(:to => "subject", :in => RDF::DC)
    map.language(:to => "language", :in => RDF::DC)
    map.date(:to => "date", :in => RDF::DC)
    map.rights(:to => "rights", :in => RDF::DC)
    map.resource_type(:to => "type", :in => RDF::DC)
    map.format(:to => "format", :in => RDF::DC)
    map.identifier(:to => "identifier", :in => RDF::DC)
    map.based_near(:to => "based_near", :in => RDF::FOAF)
    map.related_url(:to => "seeAlso", :in => RDF::RDFS)
  end
end
