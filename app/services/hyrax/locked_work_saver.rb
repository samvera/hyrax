# frozen_string_literal: true

module Hyrax
  ##
  # Saves a work under its lock, keeping membership changes another process
  # saved since the work was read.
  #
  # The stored work is reloaded under the lock. Members added to it since the
  # work was read are kept, and members removed from it are dropped, alongside
  # the caller's own member changes. When the caller did not change membership,
  # the stored members are kept in their stored order. A representative or
  # thumbnail the caller did not change takes the stored value, since attaching
  # file sets can set them. The work's other attributes are saved as given.
  #
  # A caller that has no copy of its own to save uses {.update} instead, which
  # applies its change to the stored work under the lock.
  #
  # @example
  #   read_member_ids = work.member_ids
  #   work.member_ids += [child.id]
  #   Hyrax::LockedWorkSaver.save(work: work, read_member_ids: read_member_ids)
  #
  # @example
  #   Hyrax::LockedWorkSaver.update(id: work.id) { |stored| stored.member_ids -= [child.id] }
  class LockedWorkSaver
    include Lockable

    MEMBER_DEFAULTS = %i[representative_id thumbnail_id].freeze

    ##
    # @see #save
    def self.save(work:, read_member_ids:, changed: [], persister: Hyrax.persister, query_service: Hyrax.query_service)
      new(persister: persister, query_service: query_service)
        .save(work: work, read_member_ids: read_member_ids, changed: changed)
    end

    ##
    # @see #update
    def self.update(id:, persister: Hyrax.persister, query_service: Hyrax.query_service, &block)
      new(persister: persister, query_service: query_service).update(id: id, &block)
    end

    ##
    # @param persister [#save]
    # @param query_service [#find_by] reads the stored work; use the same
    #   adapter as `persister`
    def initialize(persister: Hyrax.persister, query_service: Hyrax.query_service)
      @persister = persister
      @query_service = query_service
    end

    ##
    # @param work [Hyrax::Work] the work, with the caller's changes applied
    # @param read_member_ids [Array<Valkyrie::ID>] the work's members when the
    #   caller read it
    # @param changed [Array<Symbol>] which of `MEMBER_DEFAULTS` the caller
    #   changed, so they are saved as given
    #
    # @return [Hyrax::Work] the saved work
    def save(work:, read_member_ids:, changed: [])
      acquire_lock_for(work.id) do
        stored = @query_service.find_by(id: work.id)
        work.member_ids = merged_member_ids(work.member_ids, stored.member_ids, read_member_ids)
        (MEMBER_DEFAULTS - changed).each { |attribute| work.public_send("#{attribute}=", stored.public_send(attribute)) }
        @persister.save(resource: work)
      end
    end

    ##
    # @param id [Valkyrie::ID]
    # @yieldparam work [Hyrax::Work] the stored work, read under its lock
    #
    # @return [Hyrax::Work] the saved work
    def update(id:)
      acquire_lock_for(id) do
        work = @query_service.find_by(id: id)
        yield work
        @persister.save(resource: work)
      end
    end

    private

    def merged_member_ids(member_ids, stored_member_ids, read_member_ids)
      return stored_member_ids if member_ids == read_member_ids

      removed = read_member_ids - stored_member_ids
      added = stored_member_ids - read_member_ids
      (member_ids - removed) + (added - member_ids)
    end
  end
end
