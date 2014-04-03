class Hydra::AdminPolicy < ActiveFedora::Base
  
  include Hydra::AdminPolicyBehavior
  include Hydra::AccessControls::Permissions 
  extend Deprecation

  has_metadata 'descMetadata', type: ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.title :type=> :text, :index_as=>[:searchable]    
  end

  has_attributes :title, :description, datastream: 'descMetadata', multiple: false
  has_attributes :license_title, datastream: 'rightsMetadata', at: [:license, :title], multiple: false
  has_attributes :license_description, datastream: 'rightsMetadata', at: [:license, :description], multiple: false
  has_attributes :license_url, datastream: 'rightsMetadata', at: [:license, :url], multiple: false

  def self.readable_by_user(user)
    Deprecation.warn(Hydra::AdminPolicy, "The class method Hydra::AdminPolicy.readable_by_user(user) is deprecated and will be removed from hydra-head 8.0.", caller)
    where_user_has_permissions(user, [:read, :edit])
  end

  def self.editable_by_user(user)
    Deprecation.warn(Hydra::AdminPolicy, "The class method Hydra::AdminPolicy.editable_by_user(user) is deprecated and will be removed from hydra-head 8.0.", caller)
    where_user_has_permissions(user, [:edit])
  end

  def self.where_user_has_permissions(user, permissions=[:edit])
    Deprecation.warn(Hydra::AdminPolicy, "The class method Hydra::AdminPolicy.where_user_has_permissions(user) is deprecated and will be removed from hydra-head 8.0.", caller)
    or_query = [] 
    RoleMapper.roles(user).each do |group|
      permissions.each do |permission|
        or_query << ActiveFedora::SolrService.solr_name("#{permission}_access_group", indexer)+":#{group}"
      end
    end
    permissions.each do |permission|
      or_query << ActiveFedora::SolrService.solr_name("#{permission}_access_person", indexer)+":#{user.user_key}"
    end
    find_with_conditions(or_query.join(" OR "))
  end

end
