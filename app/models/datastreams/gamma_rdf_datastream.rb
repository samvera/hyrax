class GammaRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
  map_predicates do |map|
    map.part_of(:to => "isPartOf", :in => RDF::DC)
    map.contributor(:in => RDF::DC)
    map.creator(:in => RDF::DC)
    map.title(:in => RDF::DC, :type => :text)
    map.description(:in => RDF::DC, :type => :text)
    map.publisher(:in => RDF::DC)
    map.date_created(:to => "created", :in => RDF::DC, :type => :date)
    map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC, :type => :date)
    map.date_modified(:to => "modified", :in => RDF::DC, :type => :date)
    map.subject(:in => RDF::DC)
    map.language(:in => RDF::DC)
    map.date(:in => RDF::DC, :type => :date)
    map.rights(:in => RDF::DC)
    map.resource_type(:to => "type", :in => RDF::DC)
    map.format(:in => RDF::DC)
    map.identifier(:in => RDF::DC)
    map.based_near(:in => RDF::FOAF)
    map.related_url(:to => "seeAlso", :in => RDF::RDFS)
  end
end
