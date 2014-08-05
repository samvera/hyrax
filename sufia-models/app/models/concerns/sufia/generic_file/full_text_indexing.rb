module Sufia
  module GenericFile
    module FullTextIndexing
      extend ActiveSupport::Concern

      included do
        has_file_datastream 'full_text', versionable: false
      end

      def append_metadata
        super
        extract_content
      end

      private

        def extract_content
          url = Blacklight.solr_config[:url] ? Blacklight.solr_config[:url] : Blacklight.solr_config["url"] ? Blacklight.solr_config["url"] : Blacklight.solr_config[:fulltext] ? Blacklight.solr_config[:fulltext]["url"] : Blacklight.solr_config[:default]["url"]
          uri = URI("#{url}/update/extract?extractOnly=true&wt=json&extractFormat=text")
          req = Net::HTTP.new(uri.host, uri.port)
          resp = req.post(uri.to_s, self.content.content, {
              'Content-type' => "#{self.mime_type};charset=utf-8",
              'Content-Length' => self.content.content.size.to_s
            })
          raise "URL '#{uri}' returned code #{resp.code}" unless resp.code == "200"
          self.content.content.rewind if self.content.content.respond_to?(:rewind)
          extracted_text = JSON.parse(resp.body)[''].rstrip
          full_text.content = extracted_text if extracted_text.present?
        rescue => e
          logger.error("Error extracting content from #{self.pid}: #{e.inspect}")
        end
    end
  end
end
