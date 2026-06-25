# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that emits the `redirects_path_tesim` Solr field for
    # resources that carry a `redirects` attribute. The field is consumed
    # by the show-page renderer via `SolrDocument#redirects_path`.
    #
    # @example
    #   class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    #     include Hyrax::Indexers::RedirectsIndexer
    #   end
    module RedirectsIndexer
      def to_solr(*args)
        super.tap do |document|
          next document unless Hyrax.config.redirects_active?
          next document unless resource.respond_to?(:redirects)
          # Valkyrie's JSONValueMapper symbolizes hash keys on read; accept either.
          # Paths are normalized at write time by Hyrax::RedirectsNormalization.
          paths = Array(resource.redirects)
                  .map { |entry| entry['path'] || entry[:path] }
                  .reject(&:blank?)
          document['redirects_path_tesim'] = paths
        end
      end
    end
  end
end
