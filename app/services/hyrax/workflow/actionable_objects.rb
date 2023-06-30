# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # Produces a list of workflow-ready objects for a given user. Results are
    # given as a presenter objects with SolrDocument-like behavior, with added
    # support for workflow states.
    #
    # @example
    #   Hyrax::Workflow::ActionableObjects.new(user: current_user).each do |object|
    #     puts object.title
    #     puts object.workflow_state
    #   end
    #
    # @see Hyrax::Workflow::ObjectInWorkflowDecorator
    class ActionableObjects
      include Enumerable

      ##
      # @!attribute [rw] user
      #   @return [::User]
      attr_accessor :user

      ##
      # @param [::User] user the user whose
      def initialize(user:)
        @user = user
      end

      ##
      # @return [Hyrax::Workflow::ObjectInWorkflowDecorator]
      def each
        return enum_for(:each) unless block_given?
        ids_and_states = id_state_pairs
        return if ids_and_states.none?

        ids_and_states.map(&:first).each do |work_id|
          docs = Hyrax::SolrQueryService.new.with_ids(ids: [work_id]).solr_documents
          docs.each do |solr_doc|
            object = ObjectInWorkflowDecorator.new(solr_doc)
            _, state = ids_and_states.find { |id, _| id == object.id }

            object.workflow_state = state

            yield object
          end
        end
      end

      private

      ##
      # @api private
      # @return [Array[String, Sipity::WorkflowState]]
      def id_state_pairs
        gids_and_states = PermissionQuery
                          .scope_entities_for_the_user(user: user)
                          .pluck(:proxy_for_global_id, :workflow_state_id)

        return [] if gids_and_states.none?

        all_states = Sipity::WorkflowState.find(gids_and_states.map(&:last).uniq)

        gids_and_states.map do |str, state_id|
          [GlobalID.new(str).model_id,
           all_states.find { |state| state.id == state_id }]
        end
      end
    end
  end
end
