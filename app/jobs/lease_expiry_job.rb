# frozen_string_literal: true
class LeaseExpiryJob < Hyrax::ApplicationJob
  def perform
    records_with_expired_leases.each do |resource|
      Hyrax::LeaseManager.release_lease_for(resource: resource) &&
        Hyrax::AccessControlList(resource).save
    end
  end

  ##
  # @return [Enumerator<String>] ids for all the objects that have expired active leases
  def records_with_expired_leases
    ids = Hyrax::LeaseService.assets_with_expired_leases.map(&:id)

    Hyrax.query_service.find_many_by_ids(ids: ids)
  end
end
