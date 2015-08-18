module Hydra::RoleMapperBehavior
  extend ActiveSupport::Concern

  module ClassMethods
    def role_names
      map.keys
    end

    ##
    # @param user_or_uid either the User object or user id
    # If you pass in a nil User object (ie. user isn't logged in), or a uid that doesn't exist, it will return an empty array
    def roles(user_or_uid)
      if user_or_uid.kind_of?(String)
        user = Hydra::Ability.user_class.find_by_user_key(user_or_uid)
        user_id = user_or_uid
      elsif user_or_uid.kind_of?(Hydra::Ability.user_class) && user_or_uid.user_key
        user = user_or_uid
        user_id = user.user_key
      end
      array = byname[user_id].dup || []
      array = array << 'registered' unless (user.nil? || user.new_record?)
      array
    end

    def whois(r)
      map[r] || []
    end

    def map
      @map ||= load_role_map
    end


    def byname
      @byname ||= map.each_with_object(Hash.new{ |h,k| h[k] = [] }) do |(role, usernames), memo|
        Array(usernames).each { |x| memo[x] << role}
      end
    end

    private
      def load_role_map
        require 'erb'
        require 'yaml'

        filename = 'config/role_map.yml'
        file = File.join(Rails.root, filename)

        unless File.exists?(file)
          raise "You are missing a role map configuration file: #{filename}. Have you run \"rails generate hydra:head\"?"
        end

        begin
          erb = ERB.new(IO.read(file)).result(binding)
        rescue
          raise("#{file} was found, but could not be parsed with ERB. \n#{$!.inspect}")
        end

        begin
          yml = YAML::load(erb)
        rescue
          raise("#{filename} was found, but could not be parsed.\n")
        end
        unless yml.is_a? Hash
          raise("#{filename} was found, but was blank or malformed.\n")
        end

        yml.fetch(Rails.env)

      end
  end
end

