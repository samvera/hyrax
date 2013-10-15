module Hydra::AccessControlsEnforcement
  extend ActiveSupport::Concern

  included do
    include Hydra::AccessControlsEvaluation
    class_attribute :solr_access_filters_logic

    # Set defaults. Each symbol identifies a _method_ that must be in
    # this class, taking one parameter (permission_types)
    # Can be changed in local apps or by plugins, eg:
    # CatalogController.include ModuleDefiningNewMethod
    # CatalogController.solr_access_filters_logic += [:new_method]
    # CatalogController.solr_access_filters_logic.delete(:we_dont_want)
    self.solr_access_filters_logic = [:apply_role_permissions, :apply_individual_permissions, :apply_superuser_permissions ]

  end
  
  protected

  def gated_discovery_filters
    # Grant access to public content
    permission_types = discovery_permissions
    user_access_filters = []
    
    permission_types.each do |type|
      user_access_filters << ActiveFedora::SolrService.solr_name("#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer) + ":public"
    end
    
    # Grant access based on user id & role
    solr_access_filters_logic.each do |method_name|
      user_access_filters += send(method_name, permission_types)
    end
    user_access_filters
  end

  def under_embargo?
    load_permissions_from_solr
    embargo_key = ActiveFedora::SolrService.solr_name("embargo_release_date", Hydra::Datastream::RightsMetadata.date_indexer)
    if @permissions_solr_document[embargo_key] 
      embargo_date = Date.parse(@permissions_solr_document[embargo_key].split(/T/)[0])
      return embargo_date > Date.parse(Time.now.to_s)
    end
    false
  end

  def is_public?
    ActiveSupport::Deprecation.warn("Hydra::AccessControlsEnforcement.is_public? has been deprecated. Use can? instead.") 
    load_permissions_from_solr
    access_key = ActiveFedora::SolrService.solr_name("access", Hydra::Datastream::RightsMetadata.indexer)
    @permissions_solr_document[access_key].present? && @permissions_solr_document[access_key].first.downcase == "public"
  end
  

  #
  # Action-specific enforcement
  #
  
  # Controller "before" filter for enforcing access controls on show actions
  # @param [Hash] opts (optional, not currently used)
  def enforce_show_permissions(opts={})
    permissions = current_ability.permissions_doc(params[:id])
    if permissions.under_embargo? && !can?(:edit, permissions)
      raise Hydra::AccessDenied.new("This item is under embargo.  You do not have sufficient access privileges to read this document.", :edit, params[:id])
    end
    unless can? :read, permissions 
      raise Hydra::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
    end
  end
  
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
  #     include Hydra::Controller::ControllerBehavior
  #     CatalogController.solr_search_params_logic << :add_access_controls_to_solr_params
  #   end
  def add_access_controls_to_solr_params(solr_parameters, user_parameters)
    apply_gated_discovery(solr_parameters, user_parameters)
  end

  
  # Which permission levels (logical OR) will grant you the ability to discover documents in a search.

  # Override this method if you want it to be something other than the default
  def discovery_permissions
    @discovery_permissions ||= ["edit","discover","read"]
  end
  def discovery_permissions= (permissions)
    @discovery_permissions = permissions
  end

  # Contrller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def apply_gated_discovery(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_discovery_filters.join(" OR ")
    logger.debug("Solr parameters: #{ solr_parameters.inspect }")
  end

  
  def apply_role_permissions(permission_types)
      # for roles
      user_access_filters = []
      current_ability.user_groups.each_with_index do |role, i|
        permission_types.each do |type|
          user_access_filters << escape_filter(ActiveFedora::SolrService.solr_name("#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer), role)
        end
      end
      user_access_filters
  end

  def escape_filter(key, value)
    [key, value.gsub(/[ :\/]/, ' ' => '\ ', '/' => '\/', ':' => '\:')].join(':')
  end

  def apply_individual_permissions(permission_types)
      # for individual person access
      user_access_filters = []
      if current_user && current_user.user_key.present?
        permission_types.each do |type|
          user_access_filters << escape_filter(ActiveFedora::SolrService.solr_name("#{type}_access_person", Hydra::Datastream::RightsMetadata.indexer), current_user.user_key)
        end
      end
      user_access_filters
  end


  # override to apply super user permissions
  def apply_superuser_permissions(permission_types)
    []
  end
  
  # This filters out objects that you want to exclude from search results.  By default it only excludes FileAssets
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def exclude_unwanted_models(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "-#{ActiveFedora::SolrService.solr_name("has_model", :symbol)}:\"info:fedora/afmodel:FileAsset\""
  end
end
