module Hydra::AccessControlsEnforcement

  private

  # If someone hits the show action while their session's viewing_context is in edit mode, 
  # this will redirect them to the edit action.
  # If they do not have sufficient privileges to edit documents, it will silently switch their session to browse mode.
  def enforce_viewing_context_for_show_requests
    if params[:viewing_context] == "browse"
      session[:viewing_context] = params[:viewing_context]
    elsif session[:viewing_context] == "edit"
      if editor?
        redirect_to :action=>:edit
      else
        session[:viewing_context] = "browse"
      end
    end
  end

  def enforce_search_permissions
    if !reader? 
      @extra_controller_params[:qt] = Blacklight.config[:public_qt]
      return @extra_controller_params
    end
  end

  def enforce_read_permissions
    unless @document['access_t'] && (@document['access_t'].first == "public" || @document['access_t'].first == "Public")
    # case @document['access_t'].first
    # when /private/
      unless reader?
        flash[:notice]= "You do not have sufficient access privileges to read this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil) and return false
      end
    end
  end

  def enforce_edit_permissions
    if !editor?
      session[:viewing_context] = "browse"
      flash[:notice] = "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
      #redirect_to :action=>:show
    end
  end

end