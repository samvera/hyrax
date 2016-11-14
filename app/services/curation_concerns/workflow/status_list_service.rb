module CurationConcerns
  module Workflow
    class StatusListService
      # @param user [User]
      def initialize(user)
        @user = user
      end

      attr_reader :user

      # TODO: We will want to paginate this
      # @return [Array<StatusRow>] a list of results that the given user can take action on.
      def each
        return enum_for(:each) unless block_given?
        solr_documents.each do |doc|
          yield doc
        end
      end

      private

        # @return [Hash<String,SolrDocument>] a hash of id to solr document
        def solr_documents
          search_solr.map { |result| SolrDocument.new(result) }
        end

        def search_solr
          actionable_roles = roles_for_user
          return [] if actionable_roles.empty?
          WorkRelation.new.search_with_conditions(
            { actionable_workflow_roles_ssim: actionable_roles },
            fl: 'id title_tesim has_model_ssim, workflow_state_name_ssim',
            rows: 1000)
        end

        # @return [Array<String>] the list of workflow-role combinations this user has
        def roles_for_user
          Sipity::Workflow.all.flat_map do |wf|
            workflow_roles_for_user_and_workflow(wf).map do |wf_role|
              "#{wf.name}-#{wf_role.role.name}"
            end
          end
        end

        # @param workflow [Sipity::Workflow]
        # @return [ActiveRecord::Relation<Sipity::WorkflowRole>]
        def workflow_roles_for_user_and_workflow(workflow)
          CurationConcerns::Workflow::PermissionQuery.scope_processing_workflow_roles_for_user_and_workflow(user: user, workflow: workflow)
        end
    end
  end
end
