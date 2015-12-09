module Sufia
  class ChangeContentDepositorService
    def self.call(generic_work_id, login, reset)
      work = ::GenericWork.find(generic_work_id)
      work.proxy_depositor = work.depositor
      work.permissions = [] if reset
      work.apply_depositor_metadata(login)
      work.file_sets.each do |f|
        f.apply_depositor_metadata(login)
        f.save!
      end
      work.save!
      work
    end
  end
end
