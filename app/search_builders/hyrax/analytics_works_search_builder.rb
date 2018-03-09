module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class WorksSearchBuilder < Hyrax::SearchBuilder
    include Hyrax::FilterByType
    self.default_processor_chain += [:filter_search, :sort_ordering]
    self.default_processor_chain -= [:only_active_works]

    def initialize(context, params = nil)
      @params = params
      super(context)
    end

    def filter_search(solr_parameters)
      solr_parameters[:fq] ||= []

      unless @params[:search][:value].nil?
        solr_parameters[:fq] << "#{@params[:search][:value]}"
      end
    end

    def sort_ordering(solr_parameters)
      solr_parameters[:sort] ||= []

      unless @params[:sort_column].nil? || @params[:order]['0'][:dir].nil?
        solr_parameters[:sort] << "#{@params[:sort_column]} #{@params[:order]['0'][:dir]}"
      end
    end

    def only_works?
      true
    end
  end
end