# frozen_string_literal: true
module Hyrax
  module SingleResult
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:find_one]
    end

    def find_one(solr_parameters)
      solr_parameters.append_filter_query("{!raw f=id}#{blacklight_params.fetch(:id)}")
    end
  end
end
