class BatchRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC
  map_predicates do |map|
    map.part(:to => "hasPart", :in => RDF::DC)
    map.batch_creator(:to => "creator", :in => RDF::DC)
    map.batch_title(:to => "title", :in => RDF::DC)
  end
end

