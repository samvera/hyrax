# will move to lib/hydra/access_control folder/namespace in release 5.x
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
    controller_action = params[:action].to_s
    delegate_method = "enforce_#{controller_action}_permissions"
    if self.respond_to?(delegate_method.to_sym, true)
      self.send(delegate_method.to_sym)
    else
      true
    end
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
    raise Blacklight::Exceptions::InvalidSolrID.new("The application is trying to retrieve permissions without specifying an asset id") if id.nil?
    solr_response = Blacklight.solr.find permissions_solr_doc_params(id).merge(extra_controller_params)
    raise Blacklight::Exceptions::InvalidSolrID.new("The solr permissions search handler didn't return anything for id \"#{id}\"") if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    [solr_response, document]
  end
  
  # Loads permissions info into @permissions_solr_response and @permissions_solr_document
  def load_permissions_from_solr(id=params[:id], extra_controller_params={})
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
      if can? :edit, params[:id]
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
  
  #
  # Action-specific enforcement
  #
  
  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    load_permissions_from_solr
    unless @permissions_solr_document['access_t'] && (@permissions_solr_document['access_t'].first == "public" || @permissions_solr_document['access_t'].first == "Public")
      if @permissions_solr_document["embargo_release_date_dt"] 
        embargo_date = Date.parse(@permissions_solr_document["embargo_release_date_dt"].split(/T/)[0])
        if embargo_date > Date.parse(Time.now.to_s)
          unless current_user && can?(:edit, params[:id])
            raise Hydra::AccessDenied.new("This item is under embargo.  You do not have sufficient access privileges to read this document.", :edit, params[:id])
          end
        end
      end
      unless can? :read, params[:id] 
        raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
      end
    end
  end
  
  # Controller "before" filter for enforcing access controls on edit actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_edit_permissions(opts={})
    logger.debug("Enforcing edit permissions")
    load_permissions_from_solr
    if !can? :edit, params[:id]
      session[:viewing_context] = "browse"
      raise Hydra::AccessDenied.new("You do not have sufficient privileges to edit this document. You have been redirected to the read-only view.", :edit, params[:id])
    else
      session[:viewing_context] = "edit"
    end
  end

  ##  This method is here for you to override
  def enforce_create_permissions(opts={})
    logger.debug("Enforcing create permissions")
    if !can? :create, ActiveFedora::Base.new
      raise Hydra::AccessDenied.new "You do not have sufficient privileges to create a new document."
    end
  end

  ## proxies to enforce_edit_permssions.  This method is here for you to override
  def enforce_update_permissions(opts={})
    enforce_edit_permissions(opts)
  end

  ## proxies to enforce_edit_permssions.  This method is here for you to override
  def enforce_delete_permissions(opts={})
    enforce_edit_permissions(opts)
  end

  ## proxies to enforce_edit_permssions.  This method is here for you to override
  def enforce_new_permissions(opts={})
    enforce_create_permissions(opts)
  end

  # Controller "before" filter for enforcing access controls on index actions
  # Currently does nothing, instead relies on 
  # @param [Hash] opts (optional, not currently used)
  def enforce_index_permissions(opts={})
    # Do nothing. Relies on enforce_search_permissions being included in the Controller's solr_search_params_logic
    return true
  end
  
  #
  # Solr query modifications
  #
  
  # Set solr_parameters to enforce appropriate permissions 
  # * Applies a lucene query to the solr :q parameter for gated discovery
  # * Uses public_qt search handler if user does not have "read" permissions
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  #
  # @example This method should be added to your Catalog Controller's solr_search_params_logic
  #   class CatalogController < ApplicationController 
  #     include Hydra::Catalog
  #     CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  #   end
  def add_access_controls_to_solr_params(solr_parameters, user_parameters)
    apply_gated_discovery(solr_parameters, user_parameters)
  end

  
  # Which permission levels (logical OR) will grant you the ability to discover documents in a search.
  # Override this method if you want it to be something other than the default
  def discovery_permissions
    ["edit","discover","read"]
  end

  # Contrller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def apply_gated_discovery(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    # Grant access to public content
    permission_types = discovery_permissions
    user_access_filters = []
    
    permission_types.each do |type|
      user_access_filters << "#{type}_access_group_t:public"
    end
    
    # Grant access based on user id & role
    unless current_user.nil?
      user_access_filters += apply_role_permissions(permission_types)
      user_access_filters += apply_individual_permissions(permission_types)
      user_access_filters += apply_superuser_permissions(permission_types)
    end
    solr_parameters[:fq] << user_access_filters.join(" OR ")
    logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end
  
  def apply_role_permissions(permission_types)
      # for roles
      user_access_filters = []
      ::RoleMapper.roles(user_key).each_with_index do |role, i|
        permission_types.each do |type|
          user_access_filters << "#{type}_access_group_t:#{role}"
        end
      end
      user_access_filters
  end

  def apply_individual_permissions(permission_types)
      # for individual person access
      user_access_filters = []
      permission_types.each do |type|
        user_access_filters << "#{type}_access_person_t:#{user_key}"        
      end
      user_access_filters
  end


  # Even though is_being_superuser? is deprecated, keep this method around (just return empty set) 
  # so developers can easily override this behavior in their local app
  def apply_superuser_permissions(permission_types)
    user_access_filters = []
    if current_user.respond_to?(:is_being_superuser?) && current_user.is_being_superuser?(session) ##Deprecated
      permission_types.each do |type|
        user_access_filters << "#{type}_access_person_t:[* TO *]"        
      end
    end
    user_access_filters
  end
  
  # proxy for {enforce_index_permissions}
  def enforce_search_permissions
    enforce_index_permissions
  end

  # proxy for {enforce_show_permissions}
  def enforce_read_permissions
    enforce_show_permissions
  end
  
  # This filters out objects that you want to exclude from search results.  By default it only excludes FileAssets
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-has_model_s:\"info:fedora/afmodel:FileAsset\""
  end
end
