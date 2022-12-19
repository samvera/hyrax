# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # @deprecated use the Hyrax::Workflow::ActionableObjects enumerator instead.
    #   that service is designed as a more efficient and ergonomic replacement
    #   for this one, and has fewer dependencies on specific indexing behavior.
    #
    # Finds a list of works that a given user can perform a workflow action on.
    class StatusListService
      ##
      # @param context_or_user [::User, #current_user]
      # @param filter_condition [String] a solr filter
      #
      # @raise [ArgumentError] if th caller fails to provide a user
      def initialize(context_or_user, filter_condition)
        Deprecation
          .warn("Use the Hyrax::Workflow::ActionableObjects enumerator instead.")

        case context_or_user
        when ::User
          @user = context_or_user
        when nil
          raise ArgumentError, "A current user MUST be provided."
        else
          Deprecation.warn('Initializing StatusListService with a controller ' \
                           '"context" is deprecated. Pass in a user instead.')
          @context = context_or_user
          @user = @context.current_user
        end
        @filter_condition = filter_condition
      end

      ##
      # @!attribute [r] context
      #   @deprecated
      #   @return [#current_user]
      attr_reader :context
      deprecation_deprecate :context

      ##
      # @todo We will want to paginate this
      # @return [Enumerable<StatusRow>] a list of results that the given user can take action on.
      def each
        return enum_for(:each) unless block_given?

        solr_documents.each do |doc|
          yield doc
        end
      end

      ##
      # @deprecated
      def user
        Deprecation.warn('This method was always intended to be private. ' \
                         'It will be removed in Hyrax 4.0')
        @user
      end

      private

      ##
      # @return [Hash<String,SolrDocument>] a hash of id to solr document
      def solr_documents
        search_solr.map { |result| ::SolrDocument.new(result) }
      end

      def search_solr
        actionable_roles = roles_for_user
        Hyrax.logger.debug("Actionable roles for #{@user.user_key} are #{actionable_roles}")
        return [] if actionable_roles.empty?
        WorkRelation.new.search_with_conditions(query(actionable_roles), method: Hyrax.config.solr_default_method)
      end

      def query(actionable_roles)
        ["{!terms f=actionable_workflow_roles_ssim}#{actionable_roles.join(',')}",
         @filter_condition]
      end

      # @return [Array<String>] the list of workflow-role combinations this user has
      def roles_for_user
        Sipity::Workflow.all.flat_map do |wf|
          workflow_roles_for_user_and_workflow(wf).map do |wf_role|
            "#{wf.permission_template.source_id}-#{wf.name}-#{wf_role.role.name}"
          end
        end
      end

      # @param workflow [Sipity::Workflow]
      # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
      def workflow_roles_for_user_and_workflow(workflow)
        Hyrax::Workflow::PermissionQuery.scope_processing_workflow_roles_for_user_and_workflow(user: @user, workflow: workflow)
      end
    end
  end
end
