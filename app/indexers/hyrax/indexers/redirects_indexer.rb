# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that emits the `redirects_path_ssim` Solr field for
    # resources that carry a `redirects` attribute. The redirect resolver
    # (`Hyrax::RedirectsController`) queries this field by path.
    #
    # Safe to include unconditionally on resource indexers — the Solr field
    # is only written when the `:redirects` Flipflop feature is enabled.
    #
    # @example
    #   class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    #     include Hyrax::Indexers::RedirectsIndexer
    #   end
    module RedirectsIndexer
      def to_solr(*args)
        super.tap do |document|
          next document unless Flipflop.redirects?
          document['redirects_path_ssim'] = Array(resource.try(:redirects))
                                            .map { |entry| entry.try(:path) }
                                            .compact
        end
      end
    end
  end
end
