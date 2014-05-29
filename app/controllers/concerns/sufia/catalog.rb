module Sufia
  module Catalog
    extend ActiveSupport::Concern
    included do
      self.solr_search_params_logic += [:only_generic_files_and_collections]
      layout "sufia-two-column"
    end

    protected

      # Limits search results just to GenericFiles and collections
      # @param solr_parameters the current solr parameters
      # @param user_parameters the current user-subitted parameters
      def only_generic_files_and_collections(solr_parameters, user_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:(\"info:fedora/afmodel:GenericFile\" \"info:fedora/afmodel:Collection\")"
      end

  end
end
