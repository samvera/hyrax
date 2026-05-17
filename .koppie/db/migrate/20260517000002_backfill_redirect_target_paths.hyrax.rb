# frozen_string_literal: true

class BackfillRedirectTargetPaths < ActiveRecord::Migration[5.2]
  def up
    return unless Hyrax::RedirectPath.where(target_path: nil).exists?

    resource_ids = Hyrax::RedirectPath.where(target_path: nil).distinct.pluck(:resource_id)
    sync = Hyrax::Transactions::Steps::SyncRedirectPaths.new

    resource_ids.each do |id|
      resource = Hyrax.query_service.find_by(id: id)
      sync.call(resource)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      Hyrax::RedirectPath.where(resource_id: id).delete_all
    end
  end

  def down
    # No-op: the structural migration handles column removal.
  end
end
