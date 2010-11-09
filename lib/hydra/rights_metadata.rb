module Hydra
class RightsMetadata < ActiveFedora::NokogiriDatastream       
  
  set_terminology do |t|
    t.root(:path=>"rightsMetadata", :xmlns=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1", :schema=>"http://github.com/projecthydra/schemas/tree/v1/rightsMetadata.xsd") 
    t.copyright {
      t.machine
      t.human_readable(:path=>"human")
    }
    t.access {
      t.human_readable(:path=>"human")
      t.machine {
        t.group
        t.person
      }
      t.person(:proxy=>[:machine, :person])
      t.group(:proxy=>[:machine, :group])
      # accessor :access_person, :term=>[:access, :machine, :person]
    }
    t.discover_access(:ref=>[:access], :attributes=>{:type=>"discover"})
    t.read_access(:ref=>[:access], :attributes=>{:type=>"read"})
    t.edit_access(:ref=>[:access], :attributes=>{:type=>"edit"})
    # A bug in OM prevnts us from declaring proxy terms at the root of a Terminology
    # t.access_person(:proxy=>[:access,:machine,:person])
    # t.access_group(:proxy=>[:access,:machine,:group])
    
    t.embargo {
      t.human_readable(:path=>"human")
      t.machine{
        t.date(:type =>"release")
      }
      t.embargo_release_date(:proxy => [:machine, :date])
    }    
  end
    
  # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
  def self.xml_template
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.rightsMetadata(:version=>"0.1", "xmlns"=>"http://hydra-collab.stanford.edu/schemas/rightsMetadata/v1") {
        xml.copyright {
          xml.human
        }
        xml.access(:type=>"discover") {
          xml.human
          xml.machine
        }
        xml.access(:type=>"read") {
          xml.human
          xml.machine
        }
        xml.access(:type=>"edit") {
          xml.human
          xml.machine
        }
        xml.embargo{
          xml.human
          xml.machine
        }        
      }
    end
    return builder.doc
  end
    
  # Returns the permissions for the selected person/group
  # If new_access_level is provided, updates the selected person/group access_level to the one specified 
  # A new_access_level of "none" will remove all access_levels for the selected person/group
  # @selector Hash in format {type => identifier}
  # @new_access_level (default nil)
  # @response Hash in format {type => access_level}.  
  # 
  # ie. 
  # permissions({:person=>"person123"})
  # => {"person123"=>"edit"}
  # permissions({:person=>"person123"}, "read")
  # => {"person123"=>"read"}
  # permissions({:person=>"person123"})
  # => {"person123"=>"read"}
  def permissions(selector, new_access_level=nil)
    
    type = selector.keys.first.to_sym
    actor = selector.values.first
    if new_access_level.nil?
      xpath = self.class.terminology.xpath_for(:access, type, actor)
      nodeset = self.find_by_terms(xpath)
      if nodeset.empty?
        return "none"
      else
        return nodeset.first.ancestors("access").first.attributes["type"].text
      end
    else
      remove_all_permissions(selector)
      unless new_access_level == "none" 
        access_type_symbol = "#{new_access_level}_access".to_sym
        result = self.update_values([access_type_symbol, type] => {"-1"=>actor})
      end
      self.dirty = true
      return new_access_level
    end
      
  end
  
  # Reports on which groups have which permissions
  # @response Hash in format {group_name => group_permissions, group_name => group_permissions}
  def groups
    return quick_search_by_type(:group)
  end
  
  # Reports on which groups have which permissions
  # @response Hash in format {person_name => person_permissions, person_name => person_permissions}
  def individuals
    return quick_search_by_type(:person)
  end
  
  # Updates permissions for all of the persons and groups in a hash
  # @params ex. {"group"=>{"group1"=>"discover","group2"=>"edit"}, "person"=>{"person1"=>"read","person2"=>"discover"}}
  # Currently restricts actor type to group or person.  Any others will be ignored
  def update_permissions(params)
    params.fetch("group", {}).each_pair {|group_id, access_level| self.permissions({"group"=>group_id}, access_level)}
    params.fetch("person", {}).each_pair {|group_id, access_level| self.permissions({"person"=>group_id}, access_level)}
  end
  
  # @type symbol (either :group or :person)
  # @response 
  # This method limits the respons to known access levels.  Probably runs a bit faster than .permissions().
  def quick_search_by_type(type)
    result = {}
    [{:discover_access=>"discover"},{:read_access=>"read"},{:edit_access=>"edit"}].each do |access_levels_hash|
      access_level = access_levels_hash.keys.first
      access_level_name = access_levels_hash.values.first
      self.find_by_terms(*[access_level, type]).each do |entry|
        result[entry.text] = access_level_name
      end
    end
    return result
  end
  
  
  private
  # Purge all access given group/person 
  def remove_all_permissions(selector)
    type = selector.keys.first.to_sym
    actor = selector.values.first
    xpath = self.class.terminology.xpath_for(:access, type, actor)
    nodes_to_purge = self.find_by_terms(xpath)
    nodes_to_purge.each {|node| node.remove}
  end
  
end
end