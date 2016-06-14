module Sufia
  module ResourceSync
    # TODO: the big assumption I'm making here is that the repository has fewer
    # than 50,000 resources to list. The Sitemap protocol is limited at 50,000
    # items, so if we require more than that, we must have multiple Resource
    # lists and add a Resource List Index to point to all of them.
    class ResourceListWriter
      attr_reader :resource_host, :capability_list_url

      def initialize(resource_host:, capability_list_url:)
        @resource_host = resource_host
        @capability_list_url = capability_list_url
      end

      def write
        builder.to_xml
      end

      private

        def builder(capability_list_url: 'http://example.com/dataset1/capabilitylist.xml')
          Nokogiri::XML::Builder.new do |xml|
            xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                       'xmlns:rs' => 'http://www.openarchives.org/rs/terms/') do
              xml['rs'].ln(rel: "up", href: capability_list_url)
              xml['rs'].md(capability: "resourcelist", at: Time.now.utc.iso8601)
              build_collections(xml)
              build_works(xml)
              build_files(xml)
            end
          end
        end

        def build_collections(xml)
          Collection.search_in_batches(public_access) do |doc_set|
            build_resources(xml, doc_set)
          end
        end

        def build_works(xml)
          CurationConcerns::WorkRelation.new.search_in_batches(public_access) do |doc_set|
            build_resources(xml, doc_set)
          end
        end

        def build_files(xml)
          FileSet.search_in_batches(public_access) do |doc_set|
            build_resources(xml, doc_set)
          end
        end

        def build_resources(xml, doc_set)
          doc_set.each do |doc|
            build_resource(xml, doc)
          end
        end

        def build_resource(xml, doc)
          xml.url do
            key = doc.fetch('has_model_ssim', []).first.constantize.model_name.singular_route_key
            xml.loc routes.send(key + "_url", doc['id'], host: resource_host)
            xml.lastmod doc['system_modified_dtsi']
          end
        end

        def routes
          Rails.application.routes.url_helpers
        end

        delegate :collection_url, to: :routes

        def public_access
          { Hydra.config.permissions.read.group => 'public' }
        end
    end
  end
end
