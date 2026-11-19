# frozen_string_literal: true

module LockHelpers
  def lock_held?(key)
    Hyrax::LockManager.new(Hyrax.config.lock_time_to_live, 0, 0).lock(key) { false }
  rescue Hyrax::LockManager::UnableToAcquireLockError
    true
  end

  def save_work_elsewhere(id)
    stored = Hyrax.query_service.find_by(id: id).dup
    yield stored
    Hyrax.persister.save(resource: stored)
  end
end

RSpec.configure { |config| config.include LockHelpers }
