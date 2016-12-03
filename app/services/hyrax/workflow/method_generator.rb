module Hyrax
  module Workflow
    # Responsible for writing the database records for the given :action and :method list.
    class MethodGenerator
      # @api public
      #
      # @param action [Sipity::WorkflowAction]
      # @param list [Array<String>]
      def self.call(action:, list:)
        new(action: action, list: list).call
      end

      # @param action [Sipity::WorkflowAction]
      # @param list [Array<String>]
      def initialize(action:, list:)
        @action = action
        @list = list
      end

      attr_reader :action, :list

      def call
        if list.size < action.triggered_methods.count
          replace_list
        else
          update_list
        end
      end

      private

        def update_list
          update_from = list.dup
          nodes_to_update = action.triggered_methods.order(:weight)
          nodes_to_update.each do |node|
            node.update!(service_name: update_from.shift)
          end

          count = nodes_to_update.count
          # If there are more new values than old values, add them.
          until update_from.empty?
            action.triggered_methods.create!(service_name: update_from.shift, weight: count)
            count += 1
          end
        end

        def replace_list
          action.triggered_methods.destroy_all
          list.each_with_index do |name, i|
            action.triggered_methods.create!(service_name: name, weight: i)
          end
        end
    end
  end
end
