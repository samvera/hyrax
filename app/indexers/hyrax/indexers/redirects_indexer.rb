# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that emits the `redirects_path_ssim` Solr field for
    # resources that carry a `redirects` attribute. The redirect resolver
    # (`Hyrax::RedirectsController`) queries this field by path.
    #
    # Safe to include unconditionally on resource indexers — when the resource
    # has no `redirects` attribute (or an empty value), the Solr field is
    # set to an empty array.
    #
    # @example
    #   class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    #     include Hyrax::Indexers::RedirectsIndexer
    #   end
    module RedirectsIndexer
      def to_solr(*args)
        super.tap do |document|
          document['redirects_path_ssim'] = Array(resource.try(:redirects))
                                            .map { |entry| entry.try(:path) }
                                            .compact
        end
      end
    end
  end
end
