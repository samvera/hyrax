module CurationConcerns
  class RepositoryAuditService
    def self.audit_everything
      ::GenericFile.find_each(&:audit)
    end
  end
end
