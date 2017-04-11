module Hydra::RoleMapperBehavior
  extend ActiveSupport::Concern
  extend Deprecation

  module ClassMethods
    def role_names
      map.keys
    end

    def fetch_groups(user:)
      _groups(user.user_key)
    end

    ##
    # @param user_or_uid either the User object or user id
    # If you pass in a nil User object (ie. user isn't logged in), or a uid that doesn't exist, it will return an empty array
    def roles(user_or_uid)
      Deprecation.warn(self, "roles is deprecated and will be removed in Hydra-Head 11.  Use fetch_groups instead")
      user_id = case user_or_uid
                  when String
                    user_or_uid
                  else
                    user_or_uid.user_key
                end
      _groups(user_id)
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

      ##
      # @param user_id [String] the identfying user key
      # @return [Array<String>] a list of group names. If a nil user id, or a user id that doesn't exist is passed in, it will return an empty array
      def _groups(user_id)
        byname[user_id].dup || []
      end

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

        roles = yml.fetch(Rails.env)
        raise "No roles were found for the #{Rails.env} environment in #{file}" unless roles
        roles
      end
  end
end

