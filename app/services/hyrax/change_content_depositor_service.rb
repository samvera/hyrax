module Hyrax
  class ChangeContentDepositorService
    # @param [ActiveFedora::Base, Valkyrie::Resource] work
    # @param [User] user
    # @param [TrueClass, FalseClass] reset
    def self.call(work, user, reset)
      case work
      when ActiveFedora::Base
        call_af(work, user, reset)
      when Valkyrie::Resource
        call_valkyrie(work, user, reset)
      end
    end

    def self.call_af(work, user, reset)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(user)
      work.file_sets.each do |f|
        f.apply_depositor_metadata(user)
        f.save!
      end
      work.save!
      work
    end
    private_class_method :call_af

    def self.call_valkyrie(work, user, reset)
      if reset
        work.permission_manager.acl.permissions = []
        work.permission_manager.acl.save
      end
      work.proxy_depositor = work.depositor
      apply_depositor_metadata(work, user)
      work.file_sets.each do |f|
        apply_depositor_metadata(f, user)
      end
      work
    end
    private_class_method :call_valkyrie

    def self.apply_depositor_metadata(resource, depositor)
      depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
      resource.depositor = depositor_id if resource.respond_to? :depositor
      Hyrax::AccessControlList.new(resource: resource).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    end
    private_class_method :apply_depositor_metadata
  end
end
