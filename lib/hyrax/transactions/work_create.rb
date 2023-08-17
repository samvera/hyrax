# frozen_string_literal: true
require 'hyrax/transactions/transaction'

module Hyrax
  module Transactions
    ##
    # Creates a Work from a ChangeSet
    #
    # @since 3.0.0
    class WorkCreate < Transaction
      DEFAULT_STEPS = ['change_set.set_default_admin_set',
                       'change_set.ensure_admin_set',
                       'change_set.set_user_as_depositor',
                       'change_set.apply',
                       'work_resource.apply_permission_template',
                       'work_resource.save_acl',
                       'work_resource.add_file_sets',
                       'work_resource.change_depositor',
                       'work_resource.add_to_parent'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
