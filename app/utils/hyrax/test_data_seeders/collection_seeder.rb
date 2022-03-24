# frozen_string_literal: true
module Hyrax
  module TestDataSeeders
    # This class was created for use in rake tasks and db/seeds.rb.  It generates
    # collection that can be used in release testing.  This data can also be helpful
    # for local development testing.
    #
    # Adding collections is non-destructive.  But it may create an additional
    # collection of the same.
    #
    # @todo Do we want to assume that if a collection of the same name exists, then
    #   it is the collection we want for release testing?
    class CollectionSeeder
      class << self
        attr_accessor :logger

        def generate_seeds(logger: Logger.new(STDOUT), allow_seeding_in_production: false) # rubocop:disable Metrics/AbcSize
          raise("TestDataSeeders are not for use in production!") if Rails.env.production? && !allow_seeding_in_production
          @logger = logger

          logger.info("Adding collections...")

          create_collection("Grand Parent Collection", collection_types['Nestable only'])
          create_collection("Parent Collection", collection_types['Nestable only'])
          create_collection("Child Collection", collection_types['Nestable only'])
          create_collection("Branded Collection", collection_types['Brandable only'])
          create_collection("Discoverable Collection", collection_types['Discoverable only'])
          create_collection("Shared", collection_types['Sharable only'])
          create_collection("Share Applies to Works", collection_types['Sharable only (and works)'])
          create_collection("(SM1) Single Membership Collection", collection_types['Single Membership 1'])
          create_collection("(SM1) Another Single Membership Collection", collection_types['Single Membership 1'])
          create_collection("(SM2) Single Membership Collection", collection_types['Single Membership 2'])
          create_collection("(SM2) Another Single Membership Collection", collection_types['Single Membership 2'])
        end

        ##
        # @api private
        class NullUser
          ##
          # @return [nil]
          def user_key
            nil
          end
        end

        private

        def create_collection(title, collection_type_gid)
          return unless valid_collection_type?(title, collection_type_gid)
          return if exists?(title, collection_type_gid)

          collection = Hyrax::PcdmCollection.new(title: title, collection_type_gid: collection_type_gid)
          Hyrax.persister.save(resource: collection)
          Hyrax.publisher.publish('collection.metadata.updated', collection: collection, user: seed_user)
          logger.info("   #{collection.title.first} -- CREATED")
        end

        def seed_user
          @seed_user ||= NullUser.new
        end

        def collection_types
          @collection_types ||=
            Hyrax::CollectionType.all
                                 .each_with_object({}) { |ct, hsh| hsh[ct.title] = ct.to_global_id.to_s }
        end

        def valid_collection_type?(title, collection_type_gid)
          return true if collection_type_gid.present? && collection_types.value?(collection_type_gid.to_s)

          msg = "   #{title} -- NOT CREATED -- Collection type gid (#{collection_type_gid}) " \
                  "is invalid or doesn't exist."
          logger.info(msg)
          false
        end

        def existing_collections
          @existing_collections ||=
            Hyrax.query_service.find_all_of_model(model: Hyrax::PcdmCollection)
                 .each_with_object({}) { |col, hsh| hsh[col.title&.first] = col.collection_type_gid.to_s }
        end

        def exists?(title, collection_type_gid)
          return false unless existing_collections[title] == collection_type_gid.to_s
          logger.info("   #{title} -- ALREADY EXISTS")
          true
        end
      end
    end
  end
end
