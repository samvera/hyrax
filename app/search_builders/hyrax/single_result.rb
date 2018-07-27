module Hyrax
  module SingleResult
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:find_one]
      self.default_processor_chain.delete :filter_models
    end

    def find_one(solr_parameters)
      solr_parameters[:fq] << "{!raw f=id}#{blacklight_params.fetch(:id)}"
    end
  end
end
