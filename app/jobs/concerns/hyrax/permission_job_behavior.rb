# frozen_string_literal: true
module Hyrax
  # Grants the user's edit access on the provided FileSet
  module PermissionJobBehavior
    extend ActiveSupport::Concern

    included do
      queue_as Hyrax.config.ingest_queue_name
    end

    private

    def acl(id)
      valk_id = Valkyrie::ID.new(id)
      file_set = Hyrax.query_service.find_by(id: valk_id)
      AccessControlList.new(resource: file_set)
    end

    def user(user_key)
      ::User.find_by_user_key(user_key)
    end
  end
end
