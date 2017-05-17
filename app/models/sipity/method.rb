module Sipity
  # This is responsible for mapping the Sipity::WorkflowAction to an object that
  # responds to .call
  #
  # We store, in the database, the 'service_name'. It is the name of a constant
  # in the object space (e.g. we constantize the given service_name). The
  # resolving service object should specify that `it_behaves_like "a Hyrax workflow method"`
  #
  # @see ./lib/hyrax/specs/shared_specs/workflow_method.rb
  # @see Sipity::WorkflowAction
  # @see Hyrax::Workflow::ActionTakenService to see how this is used.
  class Method < ActiveRecord::Base
    self.table_name = 'sipity_workflow_methods'
    belongs_to :workflow_action, class_name: 'Sipity::WorkflowAction'
  end
end
