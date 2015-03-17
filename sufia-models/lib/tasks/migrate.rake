 namespace :sufia do
  namespace :migrate do

    desc "Migrate proxy deposits"
    task proxy_deposits: :environment do
      ProxyDepositRequest.all.each do |pd|
        pd.pid = pd.pid.delete "#{Sufia.config.redis_namespace}:"
        pd.save
      end
    end

    desc "Migrate audit logs"
    task audit_logs: :environment do
      ChecksumAuditLog.all.each do |cs|
        cs.pid = cs.pid.delete "#{Sufia.config.redis_namespace}:"
        cs.save
      end
    end

  end
end
