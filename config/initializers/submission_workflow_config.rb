require "hydra"
if Hydra.respond_to?(:configure)
  Hydra.configure(:shared) do |config|
  
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

  end
end