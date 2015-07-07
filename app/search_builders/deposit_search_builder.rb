class DepositSearchBuilder < Blacklight::Solr::SearchBuilder
  include Hydra::Collections::SearchBehaviors

  # includes the depositor_facet to get information on deposits.
  #  use caution when combining this with other searches as it sets the rows to zero to just get the facet information
  # @param solr_parameters the current solr parameters
  def include_depositor_facet(solr_parameters)
    solr_parameters[:"facet.field"].concat([Solrizer.solr_name("depositor", :symbol)])
    solr_parameters[:rows] = 0
  end
end
