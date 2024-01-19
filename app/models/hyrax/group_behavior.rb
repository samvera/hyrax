# frozen_string_literal: true

module Hyrax
  ##
  # An {ActiveSupport::Concern} module that contains the {Hyrax::Group} logic.  It is extracted to a
  # behavior because downstream Hyku has a Hyrax::Group that inherits from ApplicationRecord.  In
  # other words it eschews the plain old Ruby object (PORO).  However, both Hyku and Hyrax's
  # {Hyrax::Group} both have notable amounts of duplicated logic.
  #
  # @see Hyrax::Group
  module GroupBehavior
    extend ActiveSupport::Concern

    DEFAULT_NAME_PREFIX = 'group/'

    class_methods do
      ##
      # @return [String]
      # @see DEFAULT_NAME_PREFIX
      def name_prefix
        DEFAULT_NAME_PREFIX
      end

      ##
      # @return [Hyrax::Group]
      def from_agent_key(key)
        new(key.delete_prefix(name_prefix))
      end
    end

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
