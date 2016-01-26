class DepositSearchBuilder < Hydra::Collections::SearchBuilder
  # includes the depositor_facet to get information on deposits.
  #  use caution when combining this with other searches as it sets the rows to zero to just get the facet information
  # @param solr_parameters the current solr parameters
  def include_depositor_facet(solr_parameters)
    solr_parameters[:"facet.field"].concat([Solrizer.solr_name("depositor", :symbol)])

    # defualt facet limit is 10, which will only show the top 10 users not all users deposits
    solr_parameters[:"facet.limit"] = ::User.count

    # only get file information
    solr_parameters[:fq] = "has_model_ssim:GenericWork"

    # we only want the facte counts not the actual data
    solr_parameters[:rows] = 0
  end
end
