# this code will be moved/renamed to Hydra::AccessControl::RoleMapperBehavior (with the appropriate namespace changes) in Hydra 5.0
require 'yaml'
module Hydra::RoleMapperBehavior
  extend ActiveSupport::Concern

  module ClassMethods
    def role_names
      map.keys
    end
    
    # 
    # @param user_or_uid either the User object or user id
    # If you pass in a nil User object (ie. user isn't logged in), or a uid that doesn't exist, it will return an empty array
    def roles(user_or_uid)
      if user_or_uid.kind_of?(String)
        user = ::User.find_by_user_key(user_or_uid)
        user_id = user_or_uid
      elsif user_or_uid.kind_of?(::User) && !user_or_uid.uid.nil?  
        user = user_or_uid
        user_id = user.user_key
      end
      array = byname[user_id]||[]
      array = array << 'registered' unless (user.nil? || user.new_record?) 
      array
    end
    
    def whois(r)
      map[r]||[]
    end

    def map
      @map ||= YAML.load(File.open(File.join(Rails.root, "config/role_map_#{Rails.env}.yml")))
    end


    def byname
      return @byname if @byname
      m = Hash.new{|h,k| h[k]=[]}
      @byname = map.inject(m) do|memo, (role,usernames)| 
        ((usernames if usernames.respond_to?(:each)) || [usernames]).each { |x| memo[x]<<role}
        memo
      end
    end
    
  end
end

