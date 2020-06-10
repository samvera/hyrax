# frozen_string_literal: true

module Hyrax
  ##
  # Supports a range of basic Solr interactions.
  #
  # This class replaces `ActiveFedora::SolrService`, which is deprecated for
  # internal use.
  class SolrService
    COMMIT_PARAMS = { softCommit: true }.freeze

    ##
    # @!attribute [r] use_valkyrie
    #   @private
    attr_reader :use_valkyrie

    delegate :commit, to: :connection

    def initialize(use_valkyrie: Hyrax.config.query_index_from_valkyrie)
      @old_service = ActiveFedora::SolrService
      @use_valkyrie = use_valkyrie
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

      delegate :add, :commit, :count, :delete, :get, :instance, :ping, :post, :query, :delete_by_query, :search_by_id, to: :new
    end

    # Wraps rsolr get
    # @return [Hash] the hash straight form rsolr
    def get(query = nil, **args)
      # Make Hyrax.config.solr_select_path the default SOLR path
      solr_path = args.delete(:path) || Hyrax.config.solr_select_path
      args = args.merge(q: query) if query.present?

      args = args.merge(qt: 'standard') unless query.blank? || use_valkyrie
      connection.get(solr_path, params: args)
    end

    ##
    # Sends a ping request to solr
    #
    # @return [Boolean] `true` if the ping is successful
    def ping
      response = connection.get('admin/ping')
      response['status'] == "OK"
    end

    # Wraps rsolr post
    # @return [Hash] the hash straight form rsolr
    def post(query = nil, **args)
      # Make Hyrax.config.solr_select_path the default SOLR path
      solr_path = args.delete(:path) || Hyrax.config.solr_select_path
      args = args.merge(q: query) if query.present?

      args = args.merge(qt: 'standard') unless query.blank? || use_valkyrie
      connection.post(solr_path, data: args)
    end

    # Wraps get by default
    # @return [Array<SolrHit>] the response docs wrapped in SolrHit objects
    def query(query, **args)
      Rails.logger.warn rows_warning unless args.key?(:rows)
      method = args.delete(:method) || :get

      result = case method
               when :get
                 get(query, **args)
               when :post
                 post(query, **args)
               else
                 raise "Unsupported HTTP method for querying SolrService (#{method.inspect})"
               end
      result['response']['docs'].map do |doc|
        ::SolrHit.new(doc)
      end
    end

    # Wraps rsolr :delete_by_query
    def delete_by_query(query, **args)
      connection.delete_by_query(query, params: args)
    end

    # Wraps rsolr delete
    def delete(id)
      connection.delete_by_id(id, params: COMMIT_PARAMS)
    end

    # Wraps rsolr add
    # @return [Hash] the hash straight form rsolr
    def add(solr_doc, commit: true)
      connection.add(solr_doc, params: { softCommit: commit })
    end

    # Wraps rsolr count
    # @return [Hash] the hash straight form rsolr
    def count(query)
      args = { rows: 0 }
      get(query, **args)['response']['numFound'].to_i
    end

    # Wraps ActiveFedora::Base#search_by_id(id, opts)
    # @return [Array<SolrHit>] the response docs wrapped in SolrHit objects
    def search_by_id(id, opts = {})
      result = Hyrax::SolrService.query("id:#{id}", opts.merge(rows: 1))

      raise Hyrax::ObjectNotFoundError, "Object '#{id}' not found in solr" if result.empty?
      result.first
    end

    private

    ##
    # @private
    # Return the valkyrie solr index.
    #
    # Since this module depends closely on RSolr internals and makes use
    # of `#connection`, it will always need to connect to a Solr index. Other
    # valkyrie indexers used here would, at minimum, need to provide a
    # functioning `rsolr` connection.
    def valkyrie_index
      Valkyrie::IndexingAdapter.find(:solr_index)
    end

    ##
    # @api private
    def connection
      return self.class.instance.conn unless use_valkyrie
      valkyrie_index.connection
    end

    def rows_warning
      "Calling Hyrax::SolrService.get without passing an explicit value for ':rows' is not recommended. You will end up with Solr's default (usually set to 10)\nCalled by #{caller[0]}"
    end

    def rsolr_call_warning
      "Calls to Hyrax::SolrService.instance are deprecated and support will be removed from Hyrax 4.0. Use methods in Hyrax::SolrService instead."
    end
  end
end
