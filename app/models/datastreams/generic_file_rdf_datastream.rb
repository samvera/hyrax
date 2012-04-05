class GenericFileRDFDatastream < ActiveFedora::NtriplesRDFDatastream
  register_vocabularies RDF::DC, RDF::FOAF, RDF::RDFS
  map_predicates do |map|
    map.part_of(:to => "isPartOf", :in => RDF::DC)
    map.contributor(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.creator(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.title(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.description(:in => RDF::DC) do |index|
      index.type :text
      index.as :searchable, :displayable
    end
    map.publisher(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.date_created(:to => "created", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end      
    map.date_uploaded(:to => "dateSubmitted", :in => RDF::DC) do |index|
      index.type :date
      index.as :facetable, :displayable, :sortable
    end
    map.date_modified(:to => "modified", :in => RDF::DC) do |index|
      index.type :date
      index.as :facetable, :displayable, :sortable
    end
    map.subject(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.language(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.rights(:in => RDF::DC) do |index|
      index.as :displayable
    end
    map.resource_type(:to => "type", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.format(:in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.identifier(:in => RDF::DC) do |index|
      index.as :searchable, :displayable
    end
    map.based_near(:in => RDF::FOAF) do |index|
      index.as :searchable, :facetable, :displayable
    end
    map.tag(:to => "relation", :in => RDF::DC) do |index|
      index.as :searchable, :facetable, :displayable, :sortable
    end
    map.related_url(:to => "seeAlso", :in => RDF::RDFS)
  end
  LocalAuthority.register_vocabulary(self, "subject", "lc_subjects")
  LocalAuthority.register_vocabulary(self, "language", "lexvo_languages")
  LocalAuthority.register_vocabulary(self, "resource_type", "lc_genres")
  #LocalAuthority.register_vocabulary(self, "subject", "lc_genres")
  #LocalAuthority.register_vocabulary(self, "subject", "lc_names")
  #LocalAuthority.register_vocabulary(self, "subject", "dbpedia_titles")
  #LocalAuthority.register_vocabulary(self, "subject", "dbpedia_categories")
  #LocalAuthority.register_vocabulary(self, "subject", "lc_geographic")
  #LocalAuthority.register_vocabulary(self, "subject", "geonames_cities")
  #LocalAuthority.register_vocabulary(self, "subject", "lc_graphics")
  #LocalAuthority.register_vocabulary(self, "subject", "lexvo_languages")
  #LocalAuthority.register_vocabulary(self, "based_near", "lc_geographic")
  #LocalAuthority.register_vocabulary(self, "based_near", "geonames_cities")
  #LocalAuthority.register_vocabulary(self, "creator", "lc_names")
  #LocalAuthority.register_vocabulary(self, "contributor", "lc_names")
end
