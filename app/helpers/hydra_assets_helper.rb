require 'mediashelf/active_fedora_helper'

module HydraAssetsHelper
  include MediaShelf::ActiveFedoraHelper

  # Render a link to delete the given asset from the repository.
  # Includes a confirmation message. 
  def delete_asset_link(pid, asset_type_display="asset")
    result = ""
    result << "<a href=\"\#delete_dialog\" class=\"inline\">Delete this #{asset_type_display}</a>"
    result << '<div style="display:none"><div id="delete_dialog">'
      result << "<p>Do you want to permanently delete this article from the repository?</p>"
      result << form_tag(url_for(:action => "destroy", :controller => "assets", :id => pid, :method => "delete"))
      result << hidden_field_tag("_method", "delete")
      result << submit_tag("Yes, delete")
      result << "</form>"
    result << '</div></div>'
    
    return result    
  end

  def document_type(document)
    document[Blacklight.config[:show][:display_type]].first.gsub("info:fedora/afmodel:","")
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
