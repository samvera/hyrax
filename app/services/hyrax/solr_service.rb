module Hyrax
  ##
  # Supports a range of basic Solr interactions.
  #
  # This class replaces `ActiveFedora::SolrService`, which is deprecated for
  # internal use.
  class SolrService
    extend Forwardable

    def_delegators :@old_service, :add, :commit, :count, :delete

    def initialize
      @old_service = ActiveFedora::SolrService
    end

    def instance
      Valkyrie::IndexingAdapter.find(:solr_index)
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

    # Wraps rsolr get
    # @return [Hash] the hash straight form rsolr
    def get(query, args = {})
      args = args.merge(q: query, qt: 'standard')
      SolrService.instance.conn.get(Hyrax.config.solr_select_path, params: args)
    end

    # Wraps rsolr post
    # @return [Hash] the hash straight form rsolr
    def post(query, args = {})
      args = args.merge(q: query, qt: 'standard')
      SolrService.instance.conn.post(Hyrax.config.solr_select_path, data: args)
    end

    # Wraps get by default
    # @return [Array<SolrHit>] the response docs wrapped in SolrHit objects
    def query(query, args = {})
      Rails.logger.warn rows_warning unless args.key?(:rows)
      method = args.delete(:method) || :get

      result = case method
               when :get
                 get(query, args)
               when :post
                 post(query, args)
               else
                 raise "Unsupported HTTP method for querying SolrService (#{method.inspect})"
               end
      result['response']['docs'].map do |doc|
        ::SolrHit.new(doc)
      end
    end

    private

      def rows_warning
        "Calling Hyrax::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}"
      end
  end
end
