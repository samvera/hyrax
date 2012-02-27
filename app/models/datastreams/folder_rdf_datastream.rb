class FolderRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  map_predicates do |map|
    map.has_part(:to => "hasPart", :in => RDF::DC)
    map.creator(:in => RDF::DC)
    map.title(:in => RDF::DC)
  end
end

