module CurationConcerns
  # Injects a search builder filter to hide documents marked as suppressed
  module FilterSuppressed
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:only_active_works]
    end

    def only_active_works(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << '-suppressed_bsi:true'
    end
  end
end
