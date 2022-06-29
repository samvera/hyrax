# frozen_string_literal: true
module Hyrax
  class Group
    DEFAULT_NAME_PREFIX = 'group/'

    def self.name_prefix
      DEFAULT_NAME_PREFIX
    end

    ##
    # @return [Hyrax::Group]
    def self.from_agent_key(key)
      new(key.delete_prefix(name_prefix))
    end

    def initialize(name)
      @name = name
    end

    attr_reader :name

    ##
    # @return [Boolean]
    def ==(other)
      other.class == self.class && other.name == name
    end

    ##
    # @return [String] a local identifier for this group; for use (e.g.) in ACL
    #   data
    def agent_key
      self.class.name_prefix + name
    end

    def to_sipity_agent
      sipity_agent || create_sipity_agent!
    end

    private

    def sipity_agent
      Sipity::Agent.find_by(proxy_for_id: name, proxy_for_type: self.class.name)
    end

    def create_sipity_agent!
      Sipity::Agent.create!(proxy_for_id: name, proxy_for_type: self.class.name)
    end
  end
end
