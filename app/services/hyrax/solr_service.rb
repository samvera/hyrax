module Hyrax
  ##
  # Supports a range of basic Solr interactions.
  #
  # This class replaces `ActiveFedora::SolrService`, which is deprecated for
  # internal use.
  class SolrService
    extend Forwardable

    def_delegators :@old_service, :add, :count, :delete

    def initialize
      @old_service = ActiveFedora::SolrService
    end

    def instance
      # Deprecation warning for calling from outside of the Hyrax::SolrService class
      Deprecation.warn(self, rsolr_call_warning) unless caller[1].include?("#{self.class.name.underscore}.rb")

      @old_service.instance
    end

    class << self
      ##
      # We don't implement `.select_path` instead configuring this at the Hyrax
      # level
      def select_path
        raise NotImplementedError, 'This method is not available on this subclass.' \
                                   'Use `Hyrax.config.solr_select_path` instead'
      end

      delegate :add, :commit, :count, :delete, :get, :instance, :post, :query, :delete_by_query, to: :new
    end

    # Wraps rsolr get
    # @return [Hash] the hash straight form rsolr
    def get(query = nil, use_valkyrie: Hyrax.config.query_index_from_valkyrie, **args)
      # Make Hyrax.config.solr_select_path the default SOLR path
      solr_path = args.delete(:path) || Hyrax.config.solr_select_path
      args = args.merge(q: query) unless query.blank?

      if use_valkyrie
        valkyrie_index.connection.get(solr_path, params: args)
      else
        args = args.merge(qt: 'standard') unless query.blank?
        SolrService.instance.conn.get(solr_path, params: args)
      end
    end

    # Wraps rsolr post
    # @return [Hash] the hash straight form rsolr
    def post(query = nil, use_valkyrie: Hyrax.config.query_index_from_valkyrie, **args)
      # Make Hyrax.config.solr_select_path the default SOLR path
      solr_path = args.delete(:path) || Hyrax.config.solr_select_path
      args = args.merge(q: query) unless query.blank?

      if use_valkyrie
        valkyrie_index.connection.post(solr_path, data: args)
      else
        args = args.merge(qt: 'standard') unless query.blank?
        SolrService.instance.conn.post(solr_path, data: args)
      end
    end

    # Wraps get by default
    # @return [Array<SolrHit>] the response docs wrapped in SolrHit objects
    def query(query, use_valkyrie: Hyrax.config.query_index_from_valkyrie, **args)
      Rails.logger.warn rows_warning unless args.key?(:rows)
      method = args.delete(:method) || :get

      result = case method
               when :get
                 get(query, use_valkyrie: use_valkyrie, **args)
               when :post
                 post(query, use_valkyrie: use_valkyrie, **args)
               else
                 raise "Unsupported HTTP method for querying SolrService (#{method.inspect})"
               end
      result['response']['docs'].map do |doc|
        ::SolrHit.new(doc)
      end
    end

    # Wraps rsolr :commit
    def commit(use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      if use_valkyrie
        valkyrie_index.connection.commit
      else
        SolrService.instance.conn.commit
      end
    end

    # Wraps rsolr :delete_by_query
    def delete_by_query(query, use_valkyrie: Hyrax.config.query_index_from_valkyrie, **args)
      if use_valkyrie
        valkyrie_index.connection.delete_by_query(query, params: args)
      else
        SolrService.instance.conn.delete_by_query(query, params: args)
      end
    end

    private

      def valkyrie_index
        Valkyrie::IndexingAdapter.find(:solr_index)
      end

      def rows_warning
        "Calling Hyrax::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}"
      end

      def rsolr_call_warning
        "Calling Hyrax::SolrService.instance are deprecated and support will be removed from Hyrax 3.0. Use methods in Hyrax::SolrService instead."
      end
  end
end
