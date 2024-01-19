# frozen_string_literal: true

namespace :hyrax do
  namespace :embargo do
    desc 'Deactivate embargoes for which the lift date has past'
    task deactivate_expired: :environment do
      ids = Hyrax::EmbargoService.assets_with_expired_embargoes.map(&:id)

      Hyrax.query_service.find_many_by_ids(ids: ids).each do |resource|
        Hyrax::EmbargoManager.release_embargo_for(resource: resource) &&
          Hyrax.persister.save(resource: resource.embargo) &&
          Hyrax::AccessControlList(resource).save
      end
    end
  end

  namespace :lease do
    desc 'Deactivate leases for which the expiration date has past'
    task deactivate_expired: :environment do
      ids = Hyrax::LeaseService.assets_with_expired_leases.map(&:id)

      Hyrax.query_service.find_many_by_ids(ids: ids).each do |resource|
        Hyrax::LeaseManager.release_lease_for(resource: resource) &&
          Hyrax.persister.save(resource: resource.lease) &&
          Hyrax::AccessControlList(resource).save
      end
    end
  end
end
