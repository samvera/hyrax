require 'sanitize'
require 'deprecation'
module Hydra::HydraAssetsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'hydra-head 5.x'

  # Create a link for creating a new asset of the specified content_type
  # If user is not logged in, the link leads to the login page with appropriate redirect params for creating the asset after logging in
  # @param [String] link_label for the link
  # @param [String] content_type 
  def link_to_create_asset(link_label, content_type)
    if current_user
      link_to link_label, new_hydra_asset_path( :content_type => content_type), :class=>"create_asset"
    else      
      link_to link_label, new_user_session_path(:redirect_params => {:action => "new", :controller=> "assets", :content_type => content_type}), :class=>"create_asset"
    end
  end
  deprecation_deprecate :link_to_create_asset
  
  # Render a link to delete the given asset from the repository.
  # Includes a confirmation message. 
  def delete_asset_link(pid, asset_type_display="asset")
    "<a href=\"#{ url_for(:action=>:delete, :controller=>:catalog, :id=>pid)}\" class=\"delete_asset_link\" >Delete this #{asset_type_display}</a>".html_safe
  end
  deprecation_deprecate :delete_asset_link

  def document_type(document)
    if (document[blacklight_config.show.display_type]) 
      document[blacklight_config.show.display_type].first.gsub("info:fedora/afmodel:","")
    else ""
    end
  end
  deprecation_deprecate :document_type

  def get_person_from_role(doc,role,opts={})  
    i = 0
    while i < 10
      persons_roles = doc["person_#{i}_role_t"].map{|w|w.strip.downcase} unless doc["person_#{i}_role_t"].nil?
      if persons_roles and persons_roles.include?(role.downcase)
        return {:first=>doc["person_#{i}_first_name_t"], :last=>doc["person_#{i}_last_name_t"]}
      end
      i += 1
    end
  end
  deprecation_deprecate :get_person_from_role

  def get_file_asset_count(document)
    count = 0
    ### TODO switch to AF::Base.count
    obj = ActiveFedora::Base.load_instance_from_solr(document['id'], document)
    count += obj.parts.length unless obj.nil?
    count
  end
 # deprecation_deprecate :get_file_asset_count
  
  def get_file_asset_description(document)
    #TODO need test coverage
    obj = ActiveFedora::Base.load_instance_from_solr(document['id'], document)
    if obj.nil? || obj.file_objects.empty?
      return ""
    else
       fobj = FileAsset.load_instance_from_solr(obj.file_objects.first.pid)
       fobj.nil? ? "" : short_description(fobj.datastreams["descMetadata"].get_values("description").first)
    end
  end
  deprecation_deprecate :get_file_asset_description

  def short_description(desc,max=150)
    if desc.length > max
      desc = desc[0..max].concat("...")
    end
    short_description = desc.capitalize
  end
  deprecation_deprecate :short_description
  
end
