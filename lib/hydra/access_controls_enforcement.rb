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
        logger.debug("enforce_viewing_context_for_show_requests redirecting to edit")
        if params[:files]
          redirect_to :action=>:edit, :files=>true
        else
          redirect_to :action=>:edit
        end
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
      if @document["embargo_release_date_dt"] 
        embargo_date = Date.parse(@document["embargo_release_date_dt"].split(/T/)[0])
        if embargo_date > Date.parse(Time.now.to_s)
          # check for depositor raise "#{@document["depositor_t"].first} --- #{current_user.login}"
          unless current_user && current_user.login == @document["depositor_t"].first
            flash[:notice] = "This item is under embargo.  You do not have sufficient access privileges to read this document."
            redirect_to(:action=>'index', :q=>nil, :f=>nil) and return false
          end
        end
      end
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
      redirect_to :action=>:show
    else
      session[:viewing_context] = "edit"
      render :action=>:show
    end
  end

  def build_lucene_query(user_query)
    q = ""
    # start query of with user supplied query term
      q << "_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}#{user_query}\""

    # Append the exclusion of FileAssets
      q << " AND NOT _query_:\"info\\\\:fedora/afmodel\\\\:FileAsset\""

    # Append the query responsible for adding the users discovery level
      permission_types = ["edit","discover","read"]
      field_queries = []
      embargo_query = ""
      permission_types.each do |type|
        field_queries << "_query_:\"#{type}_access_group_t:public\""
      end

      unless current_user.nil?
        # for roles
        RoleMapper.roles(current_user.login).each do |role|
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_group_t:#{role}\""
          end
        end
        # for individual person access
        permission_types.each do |type|
          field_queries << "_query_:\"#{type}_access_person_t:#{current_user.login}\""
        end
        if current_user.is_being_superuser?(session)
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_person_t:[* TO *]\""
          end
        end

        # if it is the depositor and it is under embargo, that is ok
        # otherwise if it not the depositor and it is under embargo, don't show it
        embargo_query = " OR  ((_query_:\"embargo_release_date_dt:[NOW TO *]\" AND  _query_:\"depositor_t:#{current_user.login}\") AND NOT (NOT _query_:\"depositor_t:#{current_user.login}\" AND _query_:\"embargo_release_date_dt:[NOW TO *]\"))"
      end
      
      # remove anything with an embargo release date in the future  
#embargo_query = " AND NOT _query_:\"embargo_release_date_dt:[NOW TO *]\"" if embargo_query.blank?
      field_queries << " NOT _query_:\"embargo_release_date_dt:[NOW TO *]\"" if embargo_query.blank?
      
      q << " AND (#{field_queries.join(" OR ")})"
      q << embargo_query 
    return q
  end


end
