require 'mediashelf/active_fedora_helper'

module HydraAssetsHelper
  include MediaShelf::ActiveFedoraHelper

  # Create a link for creating a new asset of the specified content_type
  # If user is not logged in, the link leads to the login page with appropriate redirect params for creating the asset after logging in
  # @param [String] link_label for the link
  # @param [String] content_type 
  def link_to_create_asset(link_label, content_type)
    if current_user
      link_to link_label, {:action => 'new', :controller => 'assets', :content_type => content_type}, :class=>"create_asset"
    else      
      link_to link_label, {:action => 'new', :controller => 'user_sessions', :redirect_params => {:action => "new", :controller=> "assets", :content_type => content_type}}, :class=>"create_asset"
    end
  end
  
  # Render a link to delete the given asset from the repository.
  # Includes a confirmation message. 
  def delete_asset_link(pid, asset_type_display="asset")
    "<a href=\"#{ url_for(:action=>:delete, :controller=>:catalog, :id=>pid)}\" class=\"delete_asset_link\" >Delete this #{asset_type_display}</a>"
  end

  def document_type(document)
    if (document[Blacklight.config[:show][:display_type]]) 
      document[Blacklight.config[:show][:display_type]].first.gsub("info:fedora/afmodel:","")
    else ""
    end
  end

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

  def get_file_asset_count(document)
    count = 0
    obj = load_af_instance_from_solr(document)
    count += obj.file_objects.length unless obj.nil?
    count
  end
  
  def get_file_asset_description(document)
    obj = load_af_instance_from_solr(document)
    if obj.nil? || obj.file_objects.empty?
      return ""
    else
       fobj = FileAsset.load_instance_from_solr(obj.file_objects.first.pid)
       fobj.nil? ? "" : short_description(fobj.datastreams["descMetadata"].get_values("description").first)
    end
  end

  def short_description(desc,max=150)
    if desc.length > max
      desc = desc[0..max].concat("...")
    end
    short_description = desc.capitalize
  end
  
end
