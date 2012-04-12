class BatchRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC
  map_predicates do |map|
    map.part(:to => "hasPart", :in => RDF::DC)
    map.creator(:to => "creator", :in => RDF::DC)
    map.title(:to => "title", :in => RDF::DC)
  end
end

