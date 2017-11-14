module Hyrax
  module Workflow
    class DepositedNotification < AbstractNotification
      private

        def subject
          'Deposit has been approved'
        end

        def message
          "#{title} (#{link_to work_id, document_path}) was approved by #{user.user_key}. #{comment}"
        end

        def users_to_notify
          user_key = find_resource(work_id).depositor
          super << ::User.find_by(email: user_key)
        end

        def find_resource(id)
          query_service.find_by(id: Valkyrie::ID.new(id.to_s))
        end

        def query_service
          Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        end
    end
  end
end
