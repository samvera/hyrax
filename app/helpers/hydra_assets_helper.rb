module HydraAssetsHelper

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

end