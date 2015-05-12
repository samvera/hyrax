module Sufia
  # Extract the full text from the content using Solr's extract handler
  class FullTextExtractionService
    def self.run(generic_file)
      new(generic_file).extract
    end

    delegate :content, :logger, :mime_type, :id, to: :@generic_file

    def initialize(generic_file)
      @generic_file = generic_file
    end

    def extract
      uri = URI("#{connection_url}/update/extract?extractOnly=true&wt=json&extractFormat=text")
      req = Net::HTTP.new(uri.host, uri.port)
      resp = req.post(uri.to_s, content.content, {
          'Content-type' => "#{mime_type};charset=utf-8",
          'Content-Length' => content.content.size.to_s
        })
      raise "URL '#{uri}' returned code #{resp.code}" unless resp.code == "200"
      content.content.rewind if content.content.respond_to?(:rewind)
      JSON.parse(resp.body)[''].rstrip
    rescue => e
      logger.error("Error extracting content from #{id}: #{e.inspect}")
      return nil
    end

    def connection_url
      case
        when Blacklight.connection_config[:url] then Blacklight.connection_config[:url]
        when Blacklight.connection_config["url"] then Blacklight.connection_config["url"]
        when Blacklight.connection_config[:fulltext] then Blacklight.connection_config[:fulltext]["url"]
        else Blacklight.connection_config[:default]["url"]
      end
    end
  end
end
