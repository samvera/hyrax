# frozen_string_literal: true
module Hyrax
  # updates depositor on file sets and resets permissions if flagged. Used by
  # ChangeDepositorService to background changes to lots of file sets
  class PropagateChangeDepositorJob < ApplicationJob
    # @param work_id [Valkyrie::Id, String] the id of the work
    #             that is receiving a change of depositor
    # @param user [User] the user that will "become" the depositor of
    #             the given work
    # @param reset [TrueClass, FalseClass] when true, first clear
    #              permissions for the given work and contained file
    #              sets; regardless of true/false make the given user
    #              the depositor of the given work
    def perform(work_id, user, reset)
      work = Hyrax.query_service.find_by(id: work_id)
      Hyrax.custom_queries.find_child_file_sets(resource: work).each do |f|
        if reset
          f.permission_manager.acl.permissions = []
          f.permission_manager.acl.save
        end
        apply_depositor_metadata(f, user)
        Hyrax.persister.save(resource: f)
      end
    end

    def apply_depositor_metadata(resource, depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      resource.depositor = depositor_id if resource.respond_to? :depositor=
      Hyrax::AccessControlList.new(resource: resource).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    end
  end
end
