module Hydra::ModelMethods
  #
  # Adds metadata about the depositor to the asset 
  #
  def apply_depositor_metadata(depositor_id)
    prop_ds = self.datastreams_in_memory["properties"]
    rights_ds = self.datastreams_in_memory["rightsMetadata"]
  
    if !prop_ds.nil? && prop_ds.respond_to?(:depositor_values)
      prop_ds.depositor_values = depositor_id unless prop_ds.nil?
    end
    rights_ds.update_indexed_attributes([:edit_access, :person]=>depositor_id) unless rights_ds.nil?
    
    apply_ldap_values(depositor_id, 0)
    
    return true
  end
  
  #
  # Set the collection type (e.g. hydrangea_article) for the asset
  #
  def set_collection_type(collection)
    prop_ds = self.datastreams_in_memory["properties"]
    if !prop_ds.nil? && prop_ds.respond_to?(:collection_values)
      prop_ds.collection_values = collection
    end
  end

  # Call insert_contributor on the descMetadata datastream
  def insert_contributor(type, opts={})
    ds = self.datastreams_in_memory["descMetadata"]   
    node, index = ds.insert_contributor(type,opts)
    return node, index
  end
  
  # Call remove_contributor on the descMetadata datastream
  def remove_contributor(type, index)
    ds = self.datastreams_in_memory["descMetadata"]   
    result = ds.remove_contributor(type,index)
    return result
  end
  
  # Call to remove file obects
  def destroy_child_assets
    destroyable_child_assets.each.inject([]) do |destroyed,fo| 
        destroyed << fo.pid 
        fo.delete
        destroyed
    end

  end

  def destroyable_child_assets
    return [] unless self.file_objects
    self.file_objects.each.inject([]) do |file_assets, fo| 
      if fo.relationships[:self].has_key?(:is_part_of) && fo.relationships[:self][:is_part_of].length == 1 &&  fo.relationships[:self][:is_part_of][0].match(/#{self.pid}$/)
        file_assets << fo
      end
      file_assets
    end
  end
  
  #
  # looks through the params to fetch the computing id, then dispatches to ldap lookup to update
  #
  def update_from_computing_id(params)
    params["asset"].each_pair do |datastream_name,fields|
      if params.fetch("field_selectors",false) && params["field_selectors"].fetch(datastream_name, false)
        fields.each_pair do |field_name,field_values|
          if field_name =~ /computing_id/
            person_number = field_name[/_\d+_/].tr("_", "").to_i
            computing_id = field_values["0"]
            apply_ldap_values(computing_id, person_number)
          end
        end
      end
    end
  end
  
  #
  # applies the ldap attributes
  #
  def apply_ldap_values(computing_id, person_number)
    return if computing_id.blank? || person_number.blank?
    person = Ldap::Person.new(computing_id)
    desc_ds = self.datastreams_in_memory["descMetadata"]
    return if desc_ds.nil?
    if desc_ds.class.terminology.has_term?(:person, :computing_id)
      desc_ds.find_by_terms(:person, :computing_id)[person_number].content = person.computing_id
    end    
    desc_ds.find_by_terms(:person, :first_name)[person_number].content = person.first_name
    desc_ds.find_by_terms(:person, :last_name)[person_number].content = person.last_name
    desc_ds.find_by_terms(:person, :institution)[person_number].content = person.institution    
    desc_ds.find_by_terms(:person, :description)[person_number].content = person.department unless desc_ds.find_by_terms(:person, :description)[person_number].nil?
  end
  

end
