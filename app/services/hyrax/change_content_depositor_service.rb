module Hyrax
  class ChangeContentDepositorService
    # @param [ActiveFedora::Base] work
    # @param [User] user
    # @param [TrueClass, FalseClass] reset
    def self.call(work, user, reset)
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
  end
end
