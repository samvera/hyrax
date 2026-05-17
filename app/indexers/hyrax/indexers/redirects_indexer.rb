# frozen_string_literal: true

module Hyrax
  module Indexers
    # Emits `redirects_path_tesim` for show-page display of registered
    # aliases. See documentation/redirects.md.
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
          # Accepts string or symbol keys; Valkyrie's JSONValueMapper symbolizes on read.
          paths = Array(resource.redirects)
                  .map { |entry| entry['path'] || entry[:path] }
                  .reject(&:blank?)
          document['redirects_path_tesim'] = paths
        end
      end
    end
  end
end
