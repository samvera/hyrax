require 'linkeddata' # we need all the linked data types, because we don't know what types a service might return.I
module Hyrax
  module LinkedDataResources
    # LinkedDataResources are used for fetching a RDF::URI and retrieving the rdf_label
    #   Must be initialized with RDF::URI or URI String.
    #   Must implement #fetch_external.
    #   May extend BaseResource (which extends ActiveTriples::Resource)

    # Extend BaseResource where the rdf_label needs to be configured
    #   ie. where rdf_label needs to be gotten from properties
    #   other than those in ActiveTriples::RDFSource#default_labels
    #  @example we might have a LocationResource which expects a Geonames URI.
    #   In the RDF returned by Geonames, the closest match to a 'label' is 'name'
    #   class LocationResource < BaseResource
    #     configure rdf_label: ::RDF::Vocab::GEONAMES.name
    #   end

    # BaseResource is used where the RDF::URI is expected to include one or more
    #   ActiveTriples::RDFSource#default_labels and thus to respond to rdf_label
    class BaseResource < ActiveTriples::Resource
      # @return [String] rdf_label
      # @todo fetch from solr, if the term is already indexed
      def fetch_external
        fetch_value
        rdf_label.first.to_s
      end

      private

        # Get the RDF data from the URL by calling #fetch
        def fetch_value
          Rails.logger.info "Fetching #{rdf_subject} from the authorative source. (this is slow)"
          fetch(headers: { 'Accept'.freeze => default_accept_header })
        rescue IOError, SocketError, ArgumentError => e
          # IOError could result from a 500 error on the remote server
          # SocketError results if there is no server to connect to
          Rails.logger.error "Unable to fetch #{rdf_subject} from the authorative source.\n#{e.message}"
        end

        # Strip off the */* to work around https://github.com/rails/rails/issues/9940
        #
        # @return [String] accept headers string
        def default_accept_header
          RDF::Util::File::HttpAdapter.default_accept_header.sub(/, \*\/\*;q=0\.1\Z/, '')
        end
    end
  end
end
