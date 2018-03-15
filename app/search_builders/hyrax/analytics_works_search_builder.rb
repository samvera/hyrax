module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class AnalyticsWorksSearchBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType
    self.default_processor_chain += [:filter_search]
    self.default_processor_chain -= [:only_active_works]

    def initialize(context, params = nil)
      @params = params
      super(context)
    end

    def filter_search(solr_parameters)
      solr_parameters[:start] = @params[:start]

      return if @params[:search][:value].nil? || @params[:search][:value] == ''
      filter_params = "/.*#{@params[:search][:value]}.*/"
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "(title_tesim:#{filter_params} OR date_created_tesim:#{filter_params} OR visibility_ssi:#{filter_params} OR human_readable_type_tesim:#{filter_params})"
    end

    def only_works?
      true
    end
  end
end
