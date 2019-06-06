module Hyrax
  ##
  # Supports a range of basic Solr interactions.
  #
  # This class replaces `ActiveFedora::SolrService`, which is deprecated for
  # internal use.
  class SolrService
    extend Forwardable

    def_delegators :@old_service, :add, :commit, :count, :delete, :get, :instance, :post, :query
    def_delegators :instance, :conn

    def initialize
      @old_service = ActiveFedora::SolrService
    end

    class << self
      ##
      # We don't implement `.select_path` instead configuring this at the Hyrax
      # level
      def select_path
        raise NotImplementedError, 'This method is not available on this subclass.' \
                                   'Use `Hyrax.config.solr_select_path` instead'
      end

      delegate :add, :commit, :count, :delete, :get, :instance, :post, :query, to: :new
    end
  end
end
