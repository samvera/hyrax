# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for object lifecycle events that require workflow changes and
    # manages workflow accordingly.
    class WorkflowListener
      ##
      # @!attribute [r] factory
      #   @return [#create]
      attr_reader :factory

      ##
      # @param [#create] factory
      def initialize(factory: ::Hyrax::Workflow::WorkflowFactory)
        @factory = factory
      end

      ##
      # @param event [Dry::Event]
      def on_object_deposited(event)
        return Rails.logger.warn("Skipping workflow initialization for #{event[:object]}; no user is given\n\t#{event}") if
          event[:user].blank?

        factory.create(event[:object], {}, event[:user])
      rescue Sipity::StateError, Sipity::ConversionError => err
        # don't error on known sipity error types; log instead
        Rails.logger.error(err)
      end
    end
  end
end
