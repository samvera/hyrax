module Hydra
  module AdminPolicyBehavior
    extend ActiveSupport::Concern

    included do
      has_metadata "defaultRights", type: Hydra::Datastream::InheritableRightsMetadata 
    end

    ## Updates those permissions that are provided to it. Does not replace any permissions unless they are provided
    # @example
    #  obj.default_permissions= [{:name=>"group1", :access=>"discover", :type=>'group'},
    #  {:name=>"group2", :access=>"discover", :type=>'group'}]
    def default_permissions=(params)
      perm_hash = {'person' => defaultRights.users, 'group'=> defaultRights.groups}
      params.each do |row|
        if row[:type] == 'user' || row[:type] == 'person'
          perm_hash['person'][row[:name]] = row[:access]        
        elsif row[:type] == 'group'
          perm_hash['group'][row[:name]] = row[:access]
        else
          raise ArgumentError, "Permission type must be 'user', 'person' (alias for 'user'), or 'group'"
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
       defaultRights.users.map {|x| {:type=>'user', :access=>x[1], :name=>x[0]}})
    end

  end
end
