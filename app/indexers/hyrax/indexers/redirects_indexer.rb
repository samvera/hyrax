# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that emits the `redirects_path_ssim` Solr field for
    # resources that carry a `redirects` attribute. The redirect resolver
    # (`Hyrax::RedirectsController`) queries this field by path.
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
          document['redirects_path_ssim'] = Array(resource.redirects)
                                            .map { |entry| Hyrax::RedirectPathNormalizer.call(entry['path'] || entry[:path]) }
                                            .reject(&:blank?)
        end
      end
    end
  end
end
