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

    private

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

      def self.call_valkyrie(work, user, reset)
        if reset
          work.permission_manager.acl.permissions = []
          work.permission_manager.acl.save
        end
        work.proxy_depositor = work.depositor
        work.apply_depositor_metadata(user)
        work.file_sets.each do |f|
          f.apply_depositor_metadata(user)
        end
        work
      end
  end
end
