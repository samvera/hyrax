# frozen_string_literal: true
module Sipity
  ##
  # A proxy for the entity (e.g. a repository Object) that is being processed
  # via workflows.
  #
  # Objects of this class (and their underlying database records) represent
  # another object in the context of the workflow process. By using a proxy,
  # we can avoid polluting the repository object's data and behavior with
  # things related to workflow processing. This means we can move an object into
  # and through a workflow without making changes independently from curatorial
  # considerations (e.g. metadata changes).
  #
  # Keeping this object and interface separate also presents a clear seam for
  # alternative solutions.
  #
  # The {Sipity::Entity} relates to repository objects via a +GlobalID+ URI via
  # {#proxy_for_global_id}. Since the repository objects aren't assumed to be
  # +ActiveRecord+ or +ActiveModel+ compatible, we use the URI-based system
  # provided by +GlobalID+ to ensure that this relationship functions independent
  # of the modelling system used for the respository objects. {#proxy_for} is
  # provided as a convenience method for retrieving the underlying repository
  # object.
  #
  # Each {Sipity::Entity} holds a relationship to a {Sipity::Workflow}, which is
  # the active workflow on the object represented by the {Entity}. It also holds
  # a reference to a {Sipity::WorkflowState}, which is the current state of the
  # object within the workflow.
  #
  # @example To get the Sipity::Entity for a work
  #   work = GenericWork.first
  #   Sipity::Entity(work)
  #   => #<Sipity::Entity id: 1, proxy_for_global_id: "gid://whatever/GenericWork/3x816m604",
  # workflow_id: 8, workflow_state_id: 20, created_at: "2017-07-07 13:39:42", updated_at: "2017-07-07 13:39:42">
  #
  # @see https://github.com/rails/globalid Rails' GlobalID library
  class Entity < ActiveRecord::Base
    self.table_name = 'sipity_entities'

    belongs_to :workflow, class_name: 'Sipity::Workflow'
    belongs_to :workflow_state,
               optional: true,
               class_name: 'Sipity::WorkflowState'

    has_many :entity_specific_responsibilities, dependent: :destroy, class_name: 'Sipity::EntitySpecificResponsibility'

    has_many :comments,
             dependent: :destroy,
             class_name: 'Sipity::Comment'

    def workflow_state_name
      workflow_state&.name
    end

    # Defines the method #workflow_name
    delegate :name, to: :workflow, prefix: :workflow

    ##
    # @return [Object] the thing this +Entity+ represents.
    def proxy_for
      @proxy_for ||= GlobalID::Locator.locate(proxy_for_global_id)
    end
  end
end
