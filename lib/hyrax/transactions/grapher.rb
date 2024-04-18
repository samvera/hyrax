# frozen_string_literal: true

module Hyrax
  module Transactions
    ##
    # The purpose of this support class is to generate a tree of transactions
    # and events.
    #
    # @example
    #   $ bundle exec rails runner -e development "pp Hyrax::Transactions::Grapher.call"
    #   => {"publish" => {
    #          "class_name" => "Publish",
    #          "events" => ["on_publish"],
    #          "steps" => {
    #            "send_notice" => {
    #              "class_name" => "SendNotice",
    #              "events" => [],
    #              "steps" => [] }}}}
    #
    # @see .call
    #
    # @todo Consider output into PlantUML, MermaidJS, or `dot` notation.
    class Grapher
      # A best guess at how to find the published events within the source code
      # of the transactions.
      REGEXP_FOR_PUBLISH = %r{\.publish[\(\s]?['"]([\w\.]+)['"]}

      # Because some transactions launch other transactions within their 'call'
      REGEXP_FOR_INNER_STEPS = %r{ontainer\[['"]([\w\.]+)['"]\]}

      ##
      # @param container [Class<Dry::Container::Mixin>, Class<Hyrax::Transactions::Container>]
      #
      # @return [Hash<String, Hash>] a graph of the transaction steps.
      def self.call(container: Hyrax::Transactions::Container)
        new(container:).call
      end

      def initialize(container:)
        @container = container
      end
      attr_reader :container

      ##
      # @return [Hash<String,Hash>]
      def call
        steps = extract_steps
        treeify(steps:)
      end

      # rubocop:disable Metrics/MethodLength
      def extract_steps
        # First we gather all of the registered transactions.
        steps = {}
        container.keys.each do |key|
          step = container[key]
          step_source = File.read(step.method(:call).source_location[0])
          events = Set.new
          sub_steps = step.try(:steps) || []
          step_source.scan(REGEXP_FOR_INNER_STEPS) do |match|
            sub_steps << match[0]
          end

          step_source.scan(REGEXP_FOR_PUBLISH) do |match|
            events << match[0]
          end
          steps[key] = { "class_name" => step.class.to_s,
                         "steps" => sub_steps,
                         "events" => events.to_a }
        end
        steps
      end

      def treeify(steps:)
        unvisited_transactions = steps.keys.deep_dup

        # Now we want to tree-ify the steps; so that we can see the graph of
        # transactions and events published.
        tree = []
        steps.each_pair do |key, details|
          next if details["steps"].empty?
          unvisited_transactions.delete(key)
          sub_steps = []
          details["steps"].each do |step|
            sub_steps << extract_substeps_from(dictionary: steps,
                                               current_step: step,
                                               unvisited_transactions:)
          end

          tree << { "name" => key,
                    "class_name" => details["class_name"],
                    "events" => details["events"],
                    "steps" => sub_steps }
        end

        unvisited_transactions.each do |key|
          tree << steps[key].merge("name" => key)
        end

        tree
      end
      # rubocop:enable Metrics/MethodLength

      def extract_substeps_from(dictionary:, current_step:, unvisited_transactions:)
        # We want to avoid changing the dictionary as we're looping through
        # points of reference
        sub_step = dictionary.fetch(current_step).deep_dup
        sub_step["name"] = current_step
        unvisited_transactions.delete(current_step)
        if sub_step["steps"].present?
          sub_step_steps = []
          sub_step["steps"].each_with_object(sub_step_steps) do |st, array|
            array << extract_substeps_from(dictionary:,
                                           current_step: st,
                                           unvisited_transactions:)
          end

          sub_step["steps"] = sub_step_steps
        end
        sub_step
      end
    end
  end
end
