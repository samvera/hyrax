module Hyrax
  module Workflow
    # This is a built in function for workflow, so that a workflow action can be created that
    # grants the creator the ability to view their work.
    module GrantReadToDepositor
      # @param [#read_users=, #read_users] target (likely an ActiveRecord::Base) to which we are adding read_users for the depositor
      # @return void
      def self.call(target:, **)
        target.read_users += [target.depositor]
      end
    end
  end
end
