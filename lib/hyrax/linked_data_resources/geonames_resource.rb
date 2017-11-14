module Hyrax
  module LinkedDataResources
    # We can get richer information from the JSON API, so let's do that instead.
    class GeonamesResource < BaseResource
      attr_reader :rdf_subject

      def initialize(rdf_subject)
        @rdf_subject = RDF::URI(rdf_subject)
      end

      # Override rdf_label
      # @return [Array] rdf_label
      def rdf_label
        @rdf_label ||= [rdf_subject.to_s]
      end

      private

        # Get the data from the URL by calling Faraday#get
        def fetch_value
          Rails.logger.info "Fetching #{rdf_subject} from the authorative source."
          response = Faraday.get build_json_uri(rdf_subject)
          return rdf_subject.to_s if response.status != 200
          @rdf_label = [label(response.body)]
        rescue IOError, Faraday::ConnectionFailed, ArgumentError => e
          # IOError could result from a 500 error on the remote server
          # Faraday::ConnectionFailed results if there is no server to connect to
          Rails.logger.error "Unable to fetch #{rdf_subject} from the authorative source.\n#{e.message}"
          rdf_subject.to_s
        end

        # Construct a URI for the Geonames getJSON API
        #
        # @return [String] uri
        def build_json_uri(uri)
          "http://www.geonames.org/getJSON?geonameId=#{find_id(uri)}&username=#{Qa::Authorities::Geonames.username}"
        end

        # Extract the Geonames id from a URI in the form http://sws.geonames.org/2638077/
        #
        # @param uri [RDF::URI] the Geonames URI
        # @return [String] the Geonames id
        def find_id(uri)
          uri.to_s.split('/')[3]
        end

        # Construct a disambiguable label from the JSON response
        #
        # @param json_string [String] the Faraday::Response#body
        def label(json_string)
          item = JSON.parse(json_string)
          [item['name'], item['adminName1'], item['countryName']].compact.join(', ')
        end
    end
  end
end
