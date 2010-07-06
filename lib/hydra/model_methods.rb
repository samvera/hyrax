module Hydra::ModelMethods
  #
  # Adds metadata about the depositor to the asset 
  #
  def apply_depositor_metadata(depositor_id)
    prop_ds = self.datastreams_in_memory["properties"]
    rights_ds = self.datastreams_in_memory["rightsMetadata"]
  
    prop_ds.depositor_values = depositor_id
    rights_ds.update_indexed_attributes([:edit_access, :person]=>depositor_id)
    return true
  end

  def insert_contributor(type, opts={})
    ds = self.datastreams_in_memory["descMetadata"]   
    node, index = ds.insert_contributor(type,opts)
    return node, index
  end
end