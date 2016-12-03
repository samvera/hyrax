module Hyrax
  module ResourceSync
    class SourceDescriptionWriter
      attr_reader :capability_list_url
      def initialize(capability_list_url: 'http://example.com/dataset1/capabilitylist.xml')
        @capability_list_url = capability_list_url
      end

      def write
        builder.to_xml
      end

      private

        def builder
          Nokogiri::XML::Builder.new do |xml|
            xml.urlset('xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9',
                       'xmlns:rs' => 'http://www.openarchives.org/rs/terms/') do
              xml['rs'].ln(rel: "up", href: capability_list_url)
              xml['rs'].md(capability: "description")
              xml.url do
                xml.loc capability_list_url
                xml['rs'].md(capability: 'capabilitylist')
              end
            end
          end
        end
    end
  end
end
