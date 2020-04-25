# frozen_string_literal: true

module Hyrax
  module HealthChecks
    class SolrCheck < OkComputer::Check
      def initialize(service: Hyrax::SolrService)
        @service = service
      end

      def check
        @service.get
      rescue RSolr::Error::ConnectionRefused => err
        mark_message "Solr connection refused: #{err.message}"
        mark_failure
      rescue RuntimeError => err
        mark_message "Solr connection failed: #{err.message}"
        mark_failure
      end
    end
  end
end
