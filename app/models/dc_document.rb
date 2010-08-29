#require "active_fedora"
class DcDocument < ActiveFedora::Base

    has_relationship "parts", :is_part_of, :inbound => true
    
    # These are all the properties that don't quite fit into Qualified DC
    # Put them on the object itself (in the properties datastream) for now.
    has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
      m.field "notes", :text  
      m.field "access", :string
    end
    
    has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream do |m|
      m.field "type", :string, :xml_node => "type", :encoding => "DCMITYPE"
    end

end
