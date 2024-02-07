# frozen_string_literal: true
require 'dry/monads'

module Hyrax
  module Transactions
    module Steps
      ##
      # Saves a given work from a change_set, returning a `Dry::Monads::Result`
      # (`Success`|`Failure`).
      #
      # If the save is successful, publishes an `object.metadata.updated` event
      # for the affected resource.
      #
      # @see https://dry-rb.org/gems/dry-monads/1.0/result/
      class Save
        include Dry::Monads[:result]

        ##
        # @params [#save] persister
        def initialize(persister: Hyrax.persister, publisher: Hyrax.publisher)
          @persister = persister
          @publisher = publisher
        end

        ##
        # @param [Hyrax::ChangeSet] change_set
        # @param [::User, nil] user
        #
        # @return [Dry::Monads::Result] `Success(work)` if the change_set is
        #   applied and the resource is saved;
        #   `Failure([#to_s, change_set.resource])`, otherwise.
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def call(change_set, user: nil)
          begin
            valid_future_date?(change_set.lease, 'lease_expiration_date') if change_set.respond_to?(:lease) && change_set.lease
            valid_future_date?(change_set.embargo, 'embargo_release_date') if change_set.respond_to?(:embargo) && change_set.embargo
            new_collections = changed_collection_membership(change_set)

            unsaved = change_set.sync
            save_lease_or_embargo(unsaved)
            saved = @persister.save(resource: unsaved)
          rescue StandardError => err
            return Failure.new(["Failed save on #{change_set}\n\t#{err.message}", change_set.resource], err.backtrace.first)
          end

          # if we have a permission manager, it's acting as a local cache of another resource.
          # we want to resync changes that we had in progress so we can persist them later.
          saved.permission_manager.acl.permissions = unsaved.permission_manager.acl.permissions if
            unsaved.respond_to?(:permission_manager)

          user ||= ::User.find_by_user_key(saved.depositor)

          publish_changes(resource: saved, user: user, new: unsaved.new_record, new_collections: new_collections)
          Success(saved)
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

        private

        def valid_future_date?(item, attribute)
          return true if item.fields[attribute].blank?
          raise StandardError, "#{item.model} must use a future date" if item.fields[attribute] < Time.zone.now
        end

        def save_lease_or_embargo(unsaved)
          if unsaved.embargo.present?
            unsaved.embargo.embargo_release_date = unsaved.embargo.embargo_release_date&.to_datetime
            unsaved.embargo = @persister.save(resource: unsaved.embargo)
          end
          return if unsaved.lease.blank?

          unsaved.lease.lease_expiration_date = unsaved.lease.lease_expiration_date&.to_datetime
          unsaved.lease = @persister.save(resource: unsaved.lease)
        end

        ##
        # @param [Hyrax::ChangeSet] change_set
        #
        # @return [Array<Valkyrie::ID>]
        def changed_collection_membership(change_set)
          return [] unless change_set.changed?(:member_of_collection_ids)

          change_set.member_of_collection_ids - change_set.model.member_of_collection_ids
        end

        def publish_changes(resource:, user:, new: false, new_collections: [])
          if resource.collection?
            @publisher.publish('collection.metadata.updated', collection: resource, user: user)
          else
            @publisher.publish('object.deposited', object: resource, user: user) if new
            @publisher.publish('object.metadata.updated', object: resource, user: user)
          end

          new_collections.each do |collection_id|
            @publisher.publish('collection.membership.updated',
                               collection_id: collection_id,
                               user: user)
          end
        end
      end
    end
  end
end
