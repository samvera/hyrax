# frozen_string_literal: true
module Hyrax
  module Workflow
    ##
    # Finds a list of works that we can perform a workflow action on
    class StatusListService
      ##
      # @param context [#current_user, #logger]
      # @param filter_condition [String] a solr filter
      def initialize(context, filter_condition)
        @context = context
        @filter_condition = filter_condition
      end

      ##
      # @!attribute [r] context
      #   @return [#current_user]
      attr_reader :context

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
        context.current_user
      end

      private

      delegate :logger, to: :context

      # @return [Hash<String,SolrDocument>] a hash of id to solr document
      def solr_documents
        search_solr.map { |result| ::SolrDocument.new(result) }
      end

      def search_solr
        actionable_roles = roles_for_user
        logger.debug("Actionable roles for #{context.current_user.user_key} are #{actionable_roles}")
        return [] if actionable_roles.empty?
        WorkRelation.new.search_with_conditions(query(actionable_roles), method: :post)
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
        Hyrax::Workflow::PermissionQuery.scope_processing_workflow_roles_for_user_and_workflow(user: context.current_user, workflow: workflow)
      end
    end
  end
end
