module Sufia
  class RepositoryAuditService
    def self.audit_everything
      ::FileSet.find_each do |gf|
        CurationConcerns::FileSetAuditService.new(gf).audit
      end
    end
  end
end
