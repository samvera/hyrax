# frozen_string_literal: true

module Hyrax
  module ResourceSync
    # TODO: the big assumption I'm making here is that the repository has fewer
    # than 50,000 resources to list. The Sitemap protocol is limited at 50,000
    # items, so if we require more than that, we must have multiple Change
    # lists and add a Change List Index to point to all of them.
    class ChangeListWriter
      include Blacklight::SearchHelper

      attr_reader :resource_host, :capability_list_url
      MODIFIED_DATE_FIELD = 'timestamp'.freeze
      BEGINNING_OF_TIME = '1970-01-01T00:00:00Z'.freeze

      def initialize(resource_host:, capability_list_url:)
        @resource_host = resource_host
        @capability_list_url = capability_list_url
      end

      def write
        builder.to_xml
      end

      private

        delegate :blacklight_config, to: CatalogController

        def builder
          Nokogiri::XML::Builder.new do |xml|
            xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                       'xmlns:rs' => 'http://www.openarchives.org/rs/terms/') do
              xml['rs'].ln(rel: "up", href: capability_list_url)
              xml['rs'].md(capability: "changelist", from: from)
              build_changes(xml)
            end
          end
        end

        # return the earliest change. Otherwise BEGINNING_OF_TIME
        def from
          @from ||= begin
                      query = search_builder.query
                      query["fq"] << public_access
                      query["rows"] = 1
                      query["sort"] = MODIFIED_DATE_FIELD + ' asc'
                      result = repository.search(query).response["docs"].first
                      if result.present?
                        result.fetch(MODIFIED_DATE_FIELD)
                      else
                        BEGINNING_OF_TIME
                      end
                    end
        end

        def search_builder
          Hyrax::ExposedModelsSearchBuilder.new(self)
        end

        def build_changes(xml)
          query = search_builder.query
          query["fq"] << public_access
          query["sort"] = MODIFIED_DATE_FIELD + ' desc'
          results = repository.search(query).response["docs"]
          build_resources(xml, results)
        end

        def build_resources(xml, doc_set)
          doc_set.each do |doc|
            model = doc.fetch(Valkyrie::Persistence::Solr::Queries::MODEL, []).first.constantize
            if model == Collection
              build_resource(xml, doc, model, hyrax_routes)
            else
              build_resource(xml, doc, model, main_app_routes)
            end
          end
        end

        # @param xml [Nokogiri::XML::Builder]
        # @param doc [Hash]
        # @param routes [Module] has the routes for the object
        def build_resource(xml, doc, model, routes)
          modified_date = doc.fetch("timestamp")
          created_date = doc.fetch("created_at_dtsi")
          xml.url do
            key = model.model_name.singular_route_key
            xml.loc routes.send(key + "_url", doc['id'], host: resource_host)
            xml.lastmod modified_date
            xml['rs'].md(change: modified_date == created_date ? "created" : "updated")
          end
        end

        def main_app_routes
          Rails.application.routes.url_helpers
        end

        def hyrax_routes
          Hyrax::Engine.routes.url_helpers
        end

        delegate :collection_url, to: :routes

        def public_access
          "{!terms f=#{Hydra.config.permissions.read.group}}public"
        end
    end
  end
end
