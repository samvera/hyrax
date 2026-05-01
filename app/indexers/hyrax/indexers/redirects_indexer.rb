# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexer mixin that emits the `redirects_path_ssim` Solr field for
    # resources that carry a `redirects` attribute. The redirect resolver
    # (`Hyrax::RedirectsController`) queries this field by path.
    #
    # Include this mixin only in apps where `Hyrax.config.redirects_enabled?`
    # is true (the inclusion site is the config gate). The mixin's body
    # then needs only the Flipflop check — when the config is on, the
    # `:redirects` feature is registered and `Flipflop.redirects?` is safe
    # to call.
    #
    # @example
    #   class WorkIndexer < Hyrax::Indexers::PcdmObjectIndexer
    #     include Hyrax::Indexers::RedirectsIndexer if Hyrax.config.redirects_enabled?
    #   end
    module RedirectsIndexer
      def to_solr(*args)
        super.tap do |document|
          next document unless Flipflop.redirects?
          next document unless resource.respond_to?(:redirects)
          document['redirects_path_ssim'] = Array(resource.redirects).map(&:path).compact
        end
      end
    end
  end
end
