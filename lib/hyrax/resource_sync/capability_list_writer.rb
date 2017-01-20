module Hyrax
  module ResourceSync
    class CapabilityListWriter
      attr_reader :resource_list_url, :change_list_url, :description_url
      def initialize(resource_list_url:, change_list_url:, description_url:)
        @resource_list_url = resource_list_url
        @change_list_url = change_list_url
        @description_url = description_url
      end

      def write
        builder.to_xml
      end

      private

        def builder
          Nokogiri::XML::Builder.new do |xml|
            xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                       'xmlns:rs' => 'http://www.openarchives.org/rs/terms/') do
              xml['rs'].ln(rel: "up", href: description_url)
              xml['rs'].md(capability: "capabilitylist")

              xml.url do
                xml.loc resource_list_url
                xml['rs'].md(capability: 'resourcelist')
              end

              xml.url do
                xml.loc change_list_url
                xml['rs'].md(capability: 'changelist')
              end
            end
          end
        end
    end
  end
end
