# will move to lib/hydra/model/model_behavior.rb  (with appropriate namespace changes) in release 5.x
module Hydra::ModelMethods
  extend ActiveSupport::Concern

  included do
    unless self.class ==  Module
      self.has_many :parts, :class_name=>'ActiveFedora::Base', :property=>:is_part_of
    end
  end
  
  #
  # Adds metadata about the depositor to the asset
  # Most important behavior: if the asset has a rightsMetadata datastream, this method will add +depositor_id+ to its individual edit permissions.
  #
  def apply_depositor_metadata(depositor_id)
    prop_ds = self.datastreams["properties"]
    rights_ds = self.datastreams["rightsMetadata"]
  
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
    prop_ds = self.datastreams["properties"]
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
      if desc_metadata_ds.respond_to?(:title_values)
        desc_metadata_ds.title_values = new_title
      else
        desc_metadata_ds.title = new_title
      end
    end
  end

  # Call insert_contributor on the descMetadata datastream
  def insert_contributor(type, opts={})
    ds = self.datastreams["descMetadata"]
    node, index = ds.insert_contributor(type,opts)
    return node, index
  end
  
  # Call remove_contributor on the descMetadata datastream
  def remove_contributor(type, index)
    ds = self.datastreams["descMetadata"]
    result = ds.remove_contributor(type,index)
    return result
  end
  
  # Call to remove file objects
  def destroy_child_assets
    destroyable_child_assets.each.inject([]) do |destroyed,fo|
        destroyed << fo.pid
        fo.delete
        destroyed
    end

  end

  def destroyable_child_assets
    return [] unless self.parts
    self.parts.each.inject([]) do |file_assets, fo|
      parents = fo.ids_for_outbound(:is_part_of)
      if parents.length == 1 && parents.first.match(/#{self.pid}$/)
        file_assets << fo
      end
      file_assets
    end
  end
end
