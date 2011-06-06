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
  
  # Set the title and label on the current object
  #
  # @param [String] new_title
  # @param [Hash] opts (optional) hash of configuration options
  #
  # @example Use :only_if_blank option to only update the values when the label is empty
  #   obj.set_title_and_label("My Title", :only_if_blank=> true)
  def set_title_and_label(new_title, opts={})
    if opts[:only_if_blank]
      if self.label.nil? || self.label.empty?
        self.label = new_title
        self.set_title( new_title )
      end
    else
      self.label = new_title
      set_title( new_title )
    end
  end
  
  # Set the title and label on the current object
  #
  # @param [String] new_title
  # @param [Hash] opts (optional) hash of configuration options
  def set_title(new_title, opts={})
    if self.datastreams.has_key?("descMetadata")
      desc_metadata_ds = self.datastreams["descMetadata"]
      if desc_metadata_ds.kind_of?(ActiveFedora::NokogiriDatastream)
        if desc_metadata_ds.class.terminology.has_term?(:title)
          desc_metadata_ds.update_values([:title]=>new_title)
        end
      elsif desc_metadata_ds.respond_to?(:title_values)
        desc_metadata_ds.title_values = new_title
      end
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
      if fo.relationships[:self].has_key?(:is_part_of) && fo.relationships[:self][:is_part_of].length == 1 && fo.relationships[:self][:is_part_of][0].match(/#{self.pid}$/)
        file_assets << fo
      end
      file_assets
    end
  end
end