module Hyrax
  class RepositoryAuditService
    def self.audit_everything
      ::FileSet.find_each do |gf|
        Hyrax::FileSetAuditService.new(gf).audit
      end
    end
  end
end
