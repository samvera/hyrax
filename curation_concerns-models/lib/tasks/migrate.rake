 namespace :curation_concerns do
  namespace :migrate do

    desc "Migrate audit logs"
    task audit_logs: :environment do
      ChecksumAuditLog.all.each do |cs|
        cs.generic_file_id = cs.generic_file_id.delete "#{CurationConcerns.config.redis_namespace}:"
        cs.save
      end
    end

  end
end
