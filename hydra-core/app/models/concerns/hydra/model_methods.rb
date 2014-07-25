require 'mime/types'

module Hydra::ModelMethods

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
  def add_file(file, dsid, file_name, mime_type=nil)
    mime_type ||= best_mime_for_filename(file_name)
    options = {label: file_name, mime_type: mime_type}
    options[:dsid] = dsid if dsid
    add_file_datastream(file, options)
    set_title_and_label( file_name, only_if_blank: true )
  end

  def best_mime_for_filename(file_name)
    mime_types = MIME::Types.of(file_name)
    mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
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

end
