class FolderRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC
  map_predicates do |map|
    map.part(:to => "hasPart", :in => RDF::DC)
    map.creator(:in => RDF::DC)
    map.title(:in => RDF::DC, :type => :text)
  end
end

