class Hydra::AdminPolicy < ActiveFedora::Base
  
  # When you subclass Hydra::AdminPolicy, you probably want to include Hydra::ModelMethods so you can call apply_depositor_metadata
  # include Hydra::ModelMethods

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "defaultRights", :type => Hydra::Datastream::InheritableRightsMetadata 

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_metadata :name =>'descMetadata', :type => ActiveFedora::QualifiedDublinCoreDatastream do |ds|
    ds.field :license_url
  end

  delegate_to :descMetadata, [:title, :description], :unique=>true
  delegate :license_title, :to=>'rightsMetadata', :at=>[:license, :title], :unique=>true
  delegate :license_description, :to=>'rightsMetadata', :at=>[:license, :description], :unique=>true
  delegate :license_url, :to=>'rightsMetadata', :at=>[:license, :url], :unique=>true

  # easy access to edit_groups, etc
  include Hydra::ModelMixins::RightsMetadata 

  def self.readable_by_user(user)
    where_user_has_permissions(user, [:read, :edit])
  end

  def self.editable_by_user(user)
    where_user_has_permissions(user, [:edit])
  end

  def self.where_user_has_permissions(user, permissions=[:edit])
    or_query = [] 
    RoleMapper.roles(user).each do |group|
      permissions.each do |permission|
        or_query << "#{permission}_access_group_t:#{group}"
      end
    end
    permissions.each do |permission|
      or_query << "#{permission}_access_person_t:#{user.user_key}"
    end
    find_with_conditions(or_query.join(" OR "))
  end

  ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
  # @example
  #  obj.default_permissions= [{:name=>"group1", :access=>"discover", :type=>'group'},
  #  {:name=>"group2", :access=>"discover", :type=>'group'}]
  def default_permissions=(params)
    perm_hash = {'person' => defaultRights.individuals, 'group'=> defaultRights.groups}

    params.each do |row|
      if row[:type] == 'user'
        perm_hash['person'][row[:name]] = row[:access]
      else
        perm_hash['group'][row[:name]] = row[:access]
      end
    end
    
    defaultRights.update_permissions(perm_hash)
  end

  ## Returns a list with all the permissions on the object.
  # @example
  #  [{:name=>"group1", :access=>"discover", :type=>'group'},
  #  {:name=>"group2", :access=>"discover", :type=>'group'},
  #  {:name=>"user2", :access=>"read", :type=>'user'},
  #  {:name=>"user1", :access=>"edit", :type=>'user'},
  #  {:name=>"user3", :access=>"read", :type=>'user'}]
  def default_permissions
    (defaultRights.groups.map {|x| {:type=>'group', :access=>x[1], :name=>x[0] }} + 
      defaultRights.individuals.map {|x| {:type=>'user', :access=>x[1], :name=>x[0]}})

  end

  def to_solr(solr_doc = {}) 
    super
    solr_doc['title_display'] = solr_doc['title_t'].first if solr_doc['title_t']
    solr_doc
  end
end
