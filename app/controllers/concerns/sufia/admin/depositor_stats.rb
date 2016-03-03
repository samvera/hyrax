#  Module to gather information about the deposits in the system
#
module Sufia::Admin::DepositorStats
  extend ActiveSupport::Concern

  # we are using blacklight facet queries for some of our searches so we have to include them when we are included
  included do
    include Blacklight::Base
    copy_blacklight_config_from(CatalogController)
  end

  # Gather information about the depositors in the system
  #
  # @param [Hash] deposit_stats
  # @option deposit_stats [String] :start_date optional string to specify the start date to gather the stats from
  # @option deposit_stats [String] :end_date optional string to specify the end date to gather the stats from
  #
  def depositors(deposit_stats)
    start_datetime = Time.zone.parse(deposit_stats[:start_date]) unless deposit_stats[:start_date].blank?
    end_datetime = Time.zone.parse(deposit_stats[:end_date]).end_of_day unless deposit_stats[:end_date].blank?

    query = GenericWork.build_date_query(start_datetime, end_datetime) unless start_datetime.blank?
    sb = DepositSearchBuilder.new([:include_depositor_facet], self)
    facet_results = repository.search(sb.merge(q: query).query)
    facets = facet_results["facet_counts"]["facet_fields"]["depositor_ssim"]
    depositors = []

    # facet results come back in an array where the first item is the user and the second item is the count
    # [ abc123, 55, ccczzz, 205 ]
    # in the loop we are stepping through the array by twos to get the entire pair
    # The item at i is the key and the item at i+1 is the number of files
    (0...facets.length).step(2).each do |i|
      depositor = {}
      depositor[:key] = facets[i]
      depositor[:deposits] = facets[i + 1]
      depositor[:user] = User.find_by_user_key(depositor[:key])
      depositors << depositor
    end
    depositors
  end
end
