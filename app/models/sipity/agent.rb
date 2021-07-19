# frozen_string_literal: true
module Sipity
  ##
  # A proxy for something that can take an action.
  #
  # * A User can be an agent
  # * A Group can be an agent (though Group is outside the scope of this system)
  class Agent < ActiveRecord::Base
    self.table_name = 'sipity_agents'

    ENTITY_LEVEL_AGENT_RELATIONSHIP = 'entity_level'
    WORKFLOW_LEVEL_AGENT_RELATIONSHIP = 'workflow_level'

    has_many :workflow_responsibilities, dependent: :destroy, class_name: 'Sipity::WorkflowResponsibility'
    has_many :entity_specific_responsibilities, dependent: :destroy, class_name: 'Sipity::EntitySpecificResponsibility'

    has_many :comments,
             dependent: :destroy,
             class_name: 'Sipity::Comment'

    # Presently Hyrax::Group is a PORO not an ActiveRecord object, so
    # creating a belongs to causes Rails 5.1 to try to access methods that don't exist.
    # We do have this relationship, abet only conceptually:
    # belongs_to :proxy_for, polymorphic: true

    def proxy_for=(target)
      self.proxy_for_id = target.id
      self.proxy_for_type = target.class.name
    end

    def proxy_for
      @proxy_for ||= proxy_for_type.constantize.find(proxy_for_id)
    end
  end
end
