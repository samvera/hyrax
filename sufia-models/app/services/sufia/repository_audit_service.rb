module Sufia
  class RepositoryAuditService
    def self.audit_everything
      ::GenericFile.find_each do |gf|
        gf.audit
      end
    end
  end
end
