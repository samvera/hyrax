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
        docs = solr_documents
        entities.each do |entity|
          yield StatusRow.new(docs[entity.first], entity.last)
        end
      end

      StatusRow = Struct.new(:document, :state)

      private

        # @return [Hash<String,SolrDocument>] a hash of id to solr document
        def solr_documents
          result = ActiveFedora::Base.search_with_conditions({ id: entities.map(&:first) },
                                                             fl: 'id title_tesim has_model_ssim',
                                                             rows: 1000)
          result.each_with_object({}) { |q, h| h[q.fetch('id')] = SolrDocument.new(q) }
        end

        # @return [Array<Array>] a list of tuples with id as the first element and workflow_state as the second
        def entities
          CurationConcerns::Workflow::PermissionQuery.scope_entities_for_the_user(user: user).map do |entity|
            [entity.proxy_for_global_id.gsub(%r{.+/}, ''), entity.workflow_state.name]
          end
        end
    end
  end
end
