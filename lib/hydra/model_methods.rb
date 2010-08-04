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
  
end