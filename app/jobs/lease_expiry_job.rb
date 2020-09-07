# frozen_string_literal: true
class LeaseExpiryJob < Hyrax::ApplicationJob
  def perform
    records_with_expired_leases.each do |record|
      ExpireLeaseJob.perform_later(record)
    end
  end

  def records_with_expired_leases
    ids = Hyrax::LeaseService.assets_with_expired_leases.map(&:id)
    ids.map { |id| ActiveFedora::Base.find(id) }
  end
end
