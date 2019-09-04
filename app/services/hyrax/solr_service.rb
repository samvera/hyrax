module Hyrax
  ##
  # Supports a range of basic Solr interactions.
  #
  # This class replaces `ActiveFedora::SolrService`, which is deprecated for
  # internal use.
  class SolrService
    COMMIT_PARAMS = { softCommit: true }.freeze

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
        self.class.instance.conn.get(solr_path, params: args)
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
        self.class.instance.conn.post(solr_path, data: args)
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
        self.class.instance.conn.commit
      end
    end

    # Wraps rsolr :delete_by_query
    def delete_by_query(query, use_valkyrie: Hyrax.config.query_index_from_valkyrie, **args)
      if use_valkyrie
        valkyrie_index.connection.delete_by_query(query, params: args)
      else
        self.class.instance.conn.delete_by_query(query, params: args)
      end
    end

    # Wraps rsolr delete
    def delete(id, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      if use_valkyrie
        valkyrie_index.connection.delete_by_id(id, params: COMMIT_PARAMS)
      else
        self.class.instance.conn.delete_by_id(id, params: COMMIT_PARAMS)
      end
    end

    # Wraps rsolr add
    # @return [Hash] the hash straight form rsolr
    def add(solr_doc, use_valkyrie: Hyrax.config.query_index_from_valkyrie, commit: true)
      params = { softCommit: commit }

      if use_valkyrie
        valkyrie_index.connection.add(solr_doc, params: params)
      else
        self.class.instance.conn.add(solr_doc, params: params)
      end
    end

    # Wraps rsolr count
    # @return [Hash] the hash straight form rsolr
    def count(query, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      args = { rows: 0 }
      get(query, use_valkyrie: use_valkyrie, **args)['response']['numFound'].to_i
    end

    private

      def valkyrie_index
        Valkyrie::IndexingAdapter.find(:solr_index)
      end

      def rows_warning
        "Calling Hyrax::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}"
      end

      def rsolr_call_warning
        "Calls to Hyrax::SolrService.instance are deprecated and support will be removed from Hyrax 4.0. Use methods in Hyrax::SolrService instead."
      end
  end
end
