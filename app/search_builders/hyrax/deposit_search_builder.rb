# frozen_string_literal: true
module Hyrax
  class DepositSearchBuilder < ::SearchBuilder
    # includes the depositor_facet to get information on deposits.
    # use caution when combining this with other searches as it sets the rows to
    # zero to just get the facet information
    # @param solr_parameters the current solr parameters
    def include_depositor_facet(solr_parameters)
      solr_parameters.append_facet_fields(DepositSearchBuilder.depositor_field)

      # default facet limit is 10, which will only show the top 10 users.
      # As we want to show all user deposits, so set the facet.limit to the
      # the number of users in the database
      solr_parameters[:"facet.limit"] = ::User.count

      # we only want the facte counts not the actual data
      solr_parameters[:rows] = 0
    end

    def self.depositor_field
      "depositor_ssim"
    end

    private

    def only_works?
      true
    end
  end
end
