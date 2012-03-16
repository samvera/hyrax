class GenericFileRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
  map_predicates do |map|
    map.part_of(:to => "isPartOf", :in => RDF::DC)
    map.contributor(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.creator(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.title(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.description(:in => RDF::DC) do |index|
      index.type :text
      index.as :searchable, :displayable
    end
    map.publisher(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.date_created(:to => "created", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end      
    map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC)
    map.date_modified(:to => "modified", :in => RDF::DC)
    map.subject(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.language(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.rights(:in => RDF::DC)
    map.resource_type(:to => "type", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.format(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.identifier(:in => RDF::DC) do |index|
      index.defaults
    end
    map.based_near(:in => RDF::FOAF) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.related_url(:to => "seeAlso", :in => RDF::RDFS)
  end
end
