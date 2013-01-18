# will move to lib/hydra/model/model_behavior.rb  (with appropriate namespace changes) in release 5.x
module Hydra::ModelMethods
  extend ActiveSupport::Concern
  extend Deprecation

  included do
    unless self.class ==  Module
      self.has_many :parts, :class_name=>'ActiveFedora::Base', :property=>:is_part_of
    end
  end
  
  #
  # Adds metadata about the depositor to the asset
  # Most important behavior: if the asset has a rightsMetadata datastream, this method will add +depositor_id+ to its individual edit permissions.
  # @param [String, #user_key] depositor
  #
  def apply_depositor_metadata(depositor)
    prop_ds = self.datastreams["properties"]
    rights_ds = self.datastreams["rightsMetadata"]
    
    depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
  
    if prop_ds 
      prop_ds.depositor = depositor_id unless prop_ds.nil?
    end
    rights_ds.permissions({:person=>depositor_id}, 'edit') unless rights_ds.nil?
    return true
  end

  # Puts the contents of file (posted blob) into a datastream and sets the title and label 
  # Sets asset label and title to filename if they're empty
  #
  # @param [#read] file the IO object that is the blob
  # @param [String] file the IO object that is the blob
  def add_file(file, dsid, file_name)
    options = {:label=>file_name, :mimeType=>mime_type(file_name)}
    options[:dsid] = dsid if dsid
    add_file_datastream(file, options)
    set_title_and_label( file_name, :only_if_blank=>true )
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
  deprecation_deprecate :set_collection_type
  
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

  # Call to remove file objects
  def destroy_child_assets
    destroyable_child_assets.each.inject([]) do |destroyed,fo|
        destroyed << fo.pid
        fo.delete
        destroyed
    end

  end
  deprecation_deprecate :destroy_child_assets
  

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
  deprecation_deprecate :destroyable_child_assets

  def file_asset_count
    ### TODO switch to AF::Base.count
    parts.length
  end
  deprecation_deprecate :file_asset_count
end
