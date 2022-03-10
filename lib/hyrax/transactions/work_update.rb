# frozen_string_literal: true
module Hyrax
  module Transactions
    ##
    # @since 3.4.0
    class WorkUpdate < Transaction
      DEFAULT_STEPS = ['change_set.apply',
                       'work_resource.save_acl',
                       'work_resource.add_file_sets'].freeze

      ##
      # @see Hyrax::Transactions::Transaction
      def initialize(container: Container, steps: DEFAULT_STEPS)
        super
      end
    end
  end
end
