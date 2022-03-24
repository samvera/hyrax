# frozen_string_literal: true
module Hyrax
  module DataDestroyers
    # Clear all repository metadata from the datastore (e.g. Fedora, Postgres)
    # and from Solr.
    #
    # @note WARNING: DO NOT USE IN PRODUCTION!  The methods in this class are destructive.
    #   Data can not be recovered.
    #
    # @note When using Wings adapter, which wraps ActiveFedora, the persister wipe!
    #   method clears both Fedora and Solr.  Optionally, an index_adapter may also
    #   be set to use Valkyrie to write to a second Solr core.  If the Hyrax index
    #   adapter is the NullIndexingAdapter, that means that Valkyrie is not being
    #   used to index the repository metadata and does not need to be cleared using
    #   the Hyrax index adapter.
    #
    #   When using other Valkyrie persistence adapters, wipe! only clears the repository
    #   metadata from the datastore (e.g. ORM table in Postgres).  The index adapter
    #   is used to clear metadata from Solr.
    #
    class RepositoryMetadataDestroyer
      class << self
        attr_accessor :logger

        def destroy_metadata(logger: Logger.new(STDOUT), allow_destruction_in_production: false)
          raise("RepositoryMetadataDestroyer is not for use in production!") if Rails.env.production? && !allow_destruction_in_production
          @logger = logger

          logger.info("Destroying all repository metadata...")

          unless Hyrax.index_adapter.is_a? Valkyrie::Indexing::NullIndexingAdapter
            conn = Hyrax.index_adapter.connection
            conn.delete_by_query('*:*', params: { 'softCommit' => true })
          end
          Hyrax.persister.wipe!

          logger.info("   repository metadata -- DESTROYED")
        end
      end
    end
  end
end
