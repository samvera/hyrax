# frozen_string_literals: true

module Hyrax
  class Permission
    include ActiveModel::Model
    attr_accessor :agent_name
    attr_accessor :access
    attr_accessor :type

    def id
      [agent_name, type].join('-')
    end
  end
end
