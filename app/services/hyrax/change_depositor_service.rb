# frozen_string_literal: true
module Hyrax
  class ChangeDepositorService
    # Set the given `user` as the depositor of the given `work`; If
    # `reset` is true, first remove all previous permissions.
    #
    # Used to transfer a an existing work, and to set
    # depositor / proxy_depositor on a work newly deposited
    # on_behalf_of another user
    #
    # @param work [ActiveFedora::Base, Valkyrie::Resource] the work
    #             that is receiving a change of depositor
    # @param user [User] the user that will "become" the depositor of
    #             the given work
    # @param reset [TrueClass, FalseClass] when true, first clear
    #              permissions for the given work and contained file
    #              sets; regardless of true/false make the given user
    #              the depositor of the given work
    # @return work, updated if necessary
    def self.call(work, user, reset)
      # user_key is nil when there was no `on_behalf_of` in the form
      return work unless user&.user_key
      # Don't transfer to self
      return work if user.user_key == work.depositor

      work = case work
             when ActiveFedora::Base
               call_af(work, user, reset)
             when Valkyrie::Resource
               call_valkyrie(work, user, reset)
             end
      ChangeDepositorEventJob.perform_later(work)
      work
    end

    def self.call_af(work, user, reset)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      work.save!
      Hyrax::PropagateChangeDepositorJob.perform_later(work, user, reset) if work.file_sets.present?
      work
    end
    private_class_method :call_af

    # @todo Should this include some dependency injection regarding
    # the Hyrax.persister and Hyrax.custom_queries?
    def self.call_valkyrie(work, user, reset)
      if reset
        work.permission_manager.acl.permissions = []
        work.permission_manager.acl.save
      end

      work.proxy_depositor = work.depositor
      apply_depositor_metadata(work, user)

      work = Hyrax.persister.save(resource: work)
      file_sets = Hyrax.custom_queries.find_child_file_sets(resource: work)
      Hyrax::PropagateChangeDepositorJob.perform_later(work, user, reset) if file_sets.present?
      work
    end
    private_class_method :call_valkyrie

    def self.apply_depositor_metadata(resource, depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      resource.depositor = depositor_id if resource.respond_to? :depositor=
      Hyrax::AccessControlList.new(resource: resource).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    end
    private_class_method :apply_depositor_metadata
  end
end
