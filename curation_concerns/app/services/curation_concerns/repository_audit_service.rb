module CurationConcerns
  class RepositoryAuditService
    def self.audit_everything
      ::FileSet.find_each(&:audit)
    end
  end
end
