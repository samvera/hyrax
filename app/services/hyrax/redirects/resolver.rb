# frozen_string_literal: true

module Hyrax
  module Redirects
    # Resolves a normalized alias path to one of three outcomes:
    #
    # - {render_path: '/concern/.../<id>'}  — show page should render at the visited path
    # - {redirect_to: '/some/path'}         — caller should 301 to the given path
    # - nil                                  — no redirect applies; caller should 404
    class Resolver
      def self.call(path)
        new(path).call
      end

      def initialize(path)
        @path = path
      end

      def call
        return nil if @path.blank?
        row = Hyrax::RedirectsLookup.find_row(@path)
        return nil if row.nil?
        return { render_path: canonical_path_for(row.resource_id) } if row.display_url

        sibling = Hyrax::RedirectsLookup.display_path_for(row.resource_id)
        { redirect_to: sibling || canonical_path_for(row.resource_id) }
      rescue ActiveRecord::StatementInvalid, RSolr::Error::Http, Blacklight::Exceptions::RecordNotFound => e
        Hyrax.logger.warn "[redirects] resolver failed for #{@path.inspect}: #{e.message}"
        nil
      end

      private

      def canonical_path_for(resource_id)
        document = ::SolrDocument.find(resource_id)
        helpers = collection_document?(document) ? Hyrax::Engine.routes.url_helpers : Rails.application.routes.url_helpers
        helpers.polymorphic_path(document)
      end

      def collection_document?(document)
        Hyrax::ModelRegistry.collection_classes.any? { |klass| document.hydra_model <= klass }
      rescue StandardError
        false
      end
    end
  end
end
