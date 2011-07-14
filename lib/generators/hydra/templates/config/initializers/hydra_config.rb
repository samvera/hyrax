require "hydra"

if Hydra.respond_to?(:configure)
  Hydra.configure(:shared) do |config|
  
    config[:file_asset_types] = {
      # MZ - Commented out b/c the contents of /app are not in this branch yet.
      # :default => FileAsset, 
      # :extension_mappings => {
      #   AudioAsset => [".wav", ".mp3", ".aiff"] ,
      #   VideoAsset => [".mov", ".flv", ".mp4", ".m4v"] ,
      #   ImageAsset => [".jpeg", ".jpg", ".gif", ".png"] 
      # }
    }
    
    # This specifies the solr field names of permissions-related fields.
    # You only need to change these values if you've indexed permissions by some means other than the Hydra's built-in tooling.
    # If you change these, you must also update the permissions request handler in your solrconfig.xml to return those values
    config[:permissions] = {
      :catchall => "access_t",
      :discover => {:group =>"discover_access_group_t", :individual=>"discover_access_person_t"},
      :read => {:group =>"read_access_group_t", :individual=>"read_access_person_t"},
      :edit => {:group =>"edit_access_group_t", :individual=>"edit_access_person_t"},
      :owner => "depositor_t",
      :embargo_release_date => "embargo_release_date_dt"
    }
  end
end
