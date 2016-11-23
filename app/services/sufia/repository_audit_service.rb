module Sufia
  class RepositoryAuditService
    def self.audit_everything
      ::FileSet.find_each do |gf|
        Sufia::FileSetAuditService.new(gf).audit
      end
    end
  end
end
