module Hyrax
  class Permission
    include ActiveModel::Model
    attr_accessor :agent_name
    attr_accessor :access
    attr_accessor :type
  end
end
