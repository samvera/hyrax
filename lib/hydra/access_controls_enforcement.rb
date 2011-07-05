module Hydra::AccessControlsEnforcement
  
  def self.included(klass)
    klass.send(:include, Hydra::AccessControlsEvaluation)
  end
  
  #
  #   Access Controls Enforcement Filters
  #
  
  # Controller "before" filter that delegates enforcement based on the controller action
  # Action-specific implementations are enforce_index_permissions, enforce_show_permissions, etc.
  # @param [Hash] opts (optional, not currently used)
  #
  # @example
  #   class CatalogController < ApplicationController  
  #     before_filter :enforce_access_controls
  #   end
  def enforce_access_controls(opts={})
    controller_action = params[:action]
    if params[:action] == "destroy" then controller_action = "edit" end
    delegate_method = "enforce_#{controller_action}_permissions"
    self.send(delegate_method.to_sym)
  end
  
  
  #
  #  Solr integration
  #
  
  # returns a params hash with the permissions info for a single solr document 
  # If the id arg is nil, then the value is fetched from params[:id]
  # This method is primary called by the get_permissions_solr_response_for_doc_id method.
  # Modeled on Blacklight::SolrHelper.solr_doc_params
  # @param [String] id of the documetn to retrieve
  def permissions_solr_doc_params(id=nil)
    id ||= params[:id]
    # just to be consistent with the other solr param methods:
    {
      :qt => :permissions,
      :id => id # this assumes the document request handler will map the 'id' param to the unique key field
    }
  end
  
  # a solr query method
  # retrieve a solr document, given the doc id
  # Modeled on Blacklight::SolrHelper.get_permissions_solr_response_for_doc_id
  # @param [String] id of the documetn to retrieve
  # @param [Hash] extra_controller_params (optional)
  def get_permissions_solr_response_for_doc_id(id=nil, extra_controller_params={})
    solr_response = Blacklight.solr.find permissions_solr_doc_params(id).merge(extra_controller_params)
    raise Blacklight::Exceptions::InvalidSolrID.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    [solr_response, document]
  end
  
  # Loads permissions info into @permissions_solr_response and @permissions_solr_document
  def load_permissions_from_solr(id=nil, extra_controller_params={})
    unless !@permissions_solr_document.nil? && !@permissions_solr_response.nil?
      @permissions_solr_response, @permissions_solr_document = get_permissions_solr_response_for_doc_id(id, extra_controller_params)
    end
  end
  
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

  # Controller "before" filter for enforcing access controls on index actions
  # Points user searches at :public_qt response handler if user does not have read permissions in the application
  # @param [Hash] opts (optional, not currently used)
  def enforce_index_permissions(opts={})
    apply_gated_discovery
    if !reader? 
      @extra_controller_params[:qt] = Blacklight.config[:public_qt]
    end
  end
  
  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    load_permissions_from_solr
    unless @permissions_solr_document['access_t'] && (@permissions_solr_document['access_t'].first == "public" || @permissions_solr_document['access_t'].first == "Public")
      if @permissions_solr_document["embargo_release_date_dt"] 
        embargo_date = Date.parse(@permissions_solr_document["embargo_release_date_dt"].split(/T/)[0])
        if embargo_date > Date.parse(Time.now.to_s)
          # check for depositor raise "#{@document["depositor_t"].first} --- #{current_user.login}"
          unless current_user && current_user.login == @permissions_solr_document["depositor_t"].first
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
  
  # Controller "before" filter for enforcing access controls on edit actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_edit_permissions(opts={})
    load_permissions_from_solr
    if !editor?
      session[:viewing_context] = "browse"
      flash[:notice] = "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
      redirect_to :action=>:show
    else
      session[:viewing_context] = "edit"
      render :action=>:show
    end
  end
  
  # Contrller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
  def apply_gated_discovery
    @extra_controller_params.merge!(:q=>build_lucene_query(params[:q]))
    # logger.debug("LUCENE QUERY: #{ @extra_controller_params[:q]) }")
  end
  
  # proxy for {enforce_index_permissions}
  def enforce_search_permissions
    enforce_index_permissions
  end

  # proxy for {enforce_show_permissions}
  def enforce_read_permissions
    enforce_show_permissions
  end

  # Build the lucene query that performs gated discovery based on Hydra rightsMetadata information in Solr
  # @param [String] user_query the user's original query request that will be wrapped in access controls
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
