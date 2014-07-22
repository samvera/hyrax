class Hydra::AdminPolicy < ActiveFedora::Base
  
  include Hydra::AdminPolicyBehavior
  include Hydra::AccessControls::Permissions 

  has_metadata 'descMetadata', type: ActiveFedora::QualifiedDublinCoreDatastream do |m|
    m.title :type=> :text, :index_as=>[:searchable]    
  end

  has_attributes :title, :description, datastream: 'descMetadata', multiple: false
  has_attributes :license_title, datastream: 'rightsMetadata', at: [:license, :title], multiple: false
  has_attributes :license_description, datastream: 'rightsMetadata', at: [:license, :description], multiple: false
  has_attributes :license_url, datastream: 'rightsMetadata', at: [:license, :url], multiple: false
end
