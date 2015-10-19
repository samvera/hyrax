require 'ipaddr'
module Hydra
  class IpBasedGroups
    def self.for(remote_ip)
      groups.select { |group| group.include_ip?(remote_ip) }.map(&:name)
    end

    class Group
      attr_accessor :name
      # @param [Hash] h
      def initialize(h)
        @name = h.fetch('name')
        @subnet_strings = h.fetch('subnets')
      end

      def include_ip?(ip_string)
        ip = IPAddr.new(ip_string)
        subnets.any? { |subnet| subnet.include?(ip) }
      end

      private

        def subnets
          @subnets ||= @subnet_strings.map { |s| IPAddr.new(s) }
        end
    end

      def self.groups
        load_groups.fetch('groups').map { |h| Group.new(h) }
      end

      def self.filename
        'config/hydra_ip_range.yml'
      end

      def self.load_groups
        require 'yaml'

        file = File.join(Rails.root, filename)

        unless File.exists?(file)
          raise "ip-range configuration file not found. Expected: #{file}."
        end

        begin
          yml = YAML::load_file(file)
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
