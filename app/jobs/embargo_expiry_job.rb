# frozen_string_literal: true
class EmbargoExpiryJob < Hyrax::ApplicationJob
  def perform
    records_with_expired_embargos.each do |resource|
      Hyrax::EmbargoManager.release_embargo_for(resource: resource) &&
        Hyrax::AccessControlList(resource).save
    end
  end

  ##
  # @return [Enumerator<Valkyrie::Resource>] ids for all the objects that have expired active embargoes
  def records_with_expired_embargos
    ids = Hyrax::EmbargoService.assets_with_expired_embargoes.map(&:id)

    Hyrax.query_service.find_many_by_ids(ids: ids)
  end
end
