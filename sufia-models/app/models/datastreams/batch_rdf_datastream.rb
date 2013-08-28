class BatchRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  map_predicates do |map|
    map.part(:to => "hasPart", :in => RDF::DC)
    map.creator(:to => "creator", :in => RDF::DC)
    map.title(:to => "title", :in => RDF::DC)
    map.status(:to => "type", :in => RDF::DC)
  end
end

