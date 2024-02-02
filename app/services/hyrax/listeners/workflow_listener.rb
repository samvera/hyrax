# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for object lifecycle events that require workflow changes and
    # manages workflow accordingly.
    class WorkflowListener
      ##
      # @!attribute [rw] factory
      #   @return [#create]
      attr_accessor :factory

      ##
      # @param [#create] factory
      def initialize(factory: Hyrax::Workflow::WorkflowFactory)
        @factory = factory
      end

      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deposited(event)
        event = event.to_h
        return Hyrax.logger.warn("Skipping workflow initialization for #{event[:object]}; no user is given\n\t#{event}") if
          event[:user].blank?

        factory.create(event[:object], {}, event[:user])
      rescue Sipity::StateError, Sipity::ConversionError => err
        # don't error on known sipity error types; log instead
        Hyrax.logger.error(err)
      end

      ##
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event)
        event = event.to_h
        return unless event[:object]
        gid = Hyrax::ValkyrieGlobalIdProxy.new(resource: event[:object]).to_global_id
        return if gid.blank?
        Sipity::Entity.where(proxy_for_global_id: gid.to_s).destroy_all
      end
    end
  end
end
