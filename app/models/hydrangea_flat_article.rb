class HydrangeaFlatArticle < ActiveFedora::Base
  
  has_relationship "parts", :is_part_of, :inbound => true
  
  # simpleRightsMetadata datastream is a stand-in for the rightsMetadata datastream that will eventually have Hydra Rights Metadata xml in it
  # It will eventually be declared with this one-liner:
  # has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadataDatastream
  
  has_metadata :name => "rightsMetadata", :type => ActiveFedora::MetadataDatastream do |m|
    m.field "discover_access_group", :string
    m.field "read_access_group", :string
    m.field "edit_access_group", :string
    
    m.field "discover_access", :string
    m.field "read_access", :string
    m.field "edit_access", :string
  end
  
  # modsMetadata datastream is a stand-in for the descMetadata datastream that will eventually have MODS metadata in it
  # It will eventually be declared with this one-liner:
  # has_metadata :name => "descMetadata", :type => Hydra::ModsDatastream 
  
  has_metadata :name => "descMetadata", :type => ActiveFedora::MetadataDatastream do |m|
    m.field "title", :string
    m.field 'language', :string
    m.field 'journal_title', :string
    m.field 'publisher', :string
    m.field 'issn', :string
    m.field 'publication_date', :date
    m.field 'citation_volume', :string
    m.field 'citation_issue', :string
    m.field 'start_page', :string
    m.field 'end_page', :string
    m.field 'original_url', :string
    m.field 'contributor_role', :string
    m.field 'first_name', :string
    m.field 'last_name', :string
    m.field 'institution', :string
    m.field 'organization_name', :string
    m.field 'conference_name', :string
    m.field "abstract", :string
    m.field "topic_tag", :string
  end

  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
  end
end
