require "hydra"

# The following lines determine which user attributes your hydrangea app will use
# This configuration allows you to use the out of the box ActiveRecord associations between users and user_attributes
# It also allows you to specify your own user attributes
# The easiest way to override these methods would be to create your own module to include in User
# For example you could create a module for your local LDAP instance called MyLocalLDAPUserAttributes:
#   User.send(:include, MyLocalLDAPAttributes)
# As long as your module includes methods for full_name, affiliation, and photo the personalization_helper should function correctly
#
# NOTE: For your development environment, also specify the module in lib/user_attributes_loader.rb
User.send(:include, Hydra::GenericUserAttributes)

if Hydra.respond_to?(:configure)
  Hydra.configure(:shared) do |config|
  
    # This is used as a reference by choose_model_by_filename in FileAssetsHelper
    config[:file_asset_types] = {
      # MZ -This can only be enabled if/when we adopt replacements for ImageAsset, AudioAsset, etc. as default primitives.
      # :default => FileAsset, 
      # :extension_mappings => {
      #   AudioAsset => [".wav", ".mp3", ".aiff"] ,
      #   VideoAsset => [".mov", ".flv", ".mp4", ".m4v"] ,
      #   ImageAsset => [".jpeg", ".jpg", ".gif", ".png"] 
      # }
    }
    
    config[:submission_workflow] = {
        :mods_assets =>      [{:name => "contributor",     :edit_partial => "mods_assets/contributor_form",     :show_partial => "mods_assets/show_contributors"},
                              {:name => "publication",     :edit_partial => "mods_assets/publication_form",     :show_partial => "mods_assets/show_publication"},
                              {:name => "additional_info", :edit_partial => "mods_assets/additional_info_form", :show_partial => "mods_assets/show_additional_info"},
                              {:name => "files",           :edit_partial => "file_assets/file_assets_form",     :show_partial => "mods_assets/show_file_assets"},
                              {:name => "permissions",     :edit_partial => "permissions/permissions_form",     :show_partial => "mods_assets/show_permissions"}
                             ],
        # Not being used right now
        :generic_contents => [{:name => "description", :edit_partial => "generic_content_objects/description_form", :show_partial => "generic_contents/show_description"},
                              {:name => "files",       :edit_partial => "file_assets/file_assets_form",             :show_partial => "file_assets/index"},
                              {:name => "permissions", :edit_partial => "permissions/permissions_form",             :show_partial => "generic_contents/show_permissions"},
                              {:name => "contributor", :edit_partial => "generic_content_objects/contributor_form", :show_partial => "generic_contents/show_contributors"}
                             ]
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
