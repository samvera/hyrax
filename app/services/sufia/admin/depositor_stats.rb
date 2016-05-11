# Gather information about the depositors who have contributed to the repository
class Sufia::Admin::DepositorStats
  include Blacklight::SearchHelper

  # @param [String] start_date optionally specify the start date to gather the stats from
  # @param [String] end_date optionally specify the end date to gather the stats from
  def initialize(start_date, end_date)
    @start_dt = Time.zone.parse(start_date) unless start_date.blank?
    @end_dt = Time.zone.parse(end_date).end_of_day unless end_date.blank?
  end

  attr_accessor :start_dt, :end_dt

  def depositors
    # step through the array by twos to get each pair
    results.map do |key, deposits|
      user = User.find_by_user_key(key)
      { key: key, deposits: deposits, user: user }
    end
  end

  private

    delegate :blacklight_config, to: CatalogController
    delegate :depositor_field, to: DepositSearchBuilder

    # results come from Solr in an array where the first item is the user and
    # the second item is the count
    # [ abc123, 55, ccczzz, 205 ]
    # @return [#each] an enumerable object of tuples (user and count)
    def results
      facet_results = repository.search(query)
      facet_results.facet_fields[depositor_field].each_slice(2)
    end

    def search_builder
      DepositSearchBuilder.new([:include_depositor_facet], self)
    end

    def query
      search_builder.merge(q: date_query).query
    end

    def date_query
      GenericWork.build_date_query(start_dt, end_dt) unless start_dt.blank?
    end
end
