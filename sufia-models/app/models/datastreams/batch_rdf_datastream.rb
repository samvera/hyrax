class BatchRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  property :creator, predicate: RDF::DC.creator
  property :title, predicate: RDF::DC.title
  property :status, predicate: RDF::DC.type
end
