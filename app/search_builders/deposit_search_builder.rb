class DepositSearchBuilder < ::SearchBuilder
  # includes the depositor_facet to get information on deposits.
  # use caution when combining this with other searches as it sets the rows to
  # zero to just get the facet information
  # @param solr_parameters the current solr parameters
  def include_depositor_facet(solr_parameters)
    solr_parameters[:"facet.field"].concat([DepositSearchBuilder.depositor_field])

    # default facet limit is 10, which will only show the top 10 users.
    # As we want to show all user deposits, so set the facet.limit to the
    # the number of users in the database
    solr_parameters[:"facet.limit"] = ::User.count

    # only get work information
    solr_parameters[:fq] = Hyrax::WorkRelation.new.search_model_clause

    # we only want the facte counts not the actual data
    solr_parameters[:rows] = 0
  end

  def self.depositor_field
    @depositor_field ||= Solrizer.solr_name('depositor', :symbol).freeze
  end
end
