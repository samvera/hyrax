# frozen_string_literal: true

module Hyrax
  # See documentation/redirects.md for the redirects feature.
  class RedirectsController < ApplicationController
    CACHE_TTL = 60.seconds

    def show
      path = Hyrax::RedirectPathNormalizer.call(params[:alias_path])
      doc = lookup(path)
      raise ActionController::RoutingError, 'Not Found' if doc.blank?

      redirect_to permanent_url_for(::SolrDocument.new(doc)), status: :moved_permanently
    end

    private

    # Collections are routed by the Hyrax engine; works are routed by
    # the host app's curation-concern resources. `polymorphic_path`
    # consults a routes proxy, so we pick the right one per type.
    def permanent_url_for(document)
      proxy = collection_document?(document) ? hyrax : main_app
      polymorphic_path([proxy, document])
    end

    def collection_document?(document)
      model = document.hydra_model
      Hyrax::ModelRegistry.collection_classes.any? { |klass| model <= klass }
    rescue StandardError
      false
    end

    # TODO: bust the cache key on redirect save/destroy (Phase 1 follow-up).
    def lookup(path)
      Rails.cache.fetch(cache_key_for(path), expires_in: CACHE_TTL) do
        response = Hyrax::SolrService.get(%(redirects_path_ssim:"#{path}"), rows: 1)
        response.dig('response', 'docs')&.first
      end
    rescue RSolr::Error::Http => e
      Hyrax.logger.warn "Redirect lookup failed for #{path.inspect}: #{e.message}"
      nil
    end

    # Override in a downstream app to encode tenancy.
    def cache_key_for(path)
      ['hyrax', 'redirects', Digest::SHA1.hexdigest(path)].join('/')
    end
  end
end
