module Hyrax
  # Returns Works that the current user has permission to use.
  class WorksCountService < CountService
    SearchResultForWorkCount = Struct.new(:work_name, :updated, :work_views, :work_type, :visibility)

    # Returns list of works
    # @param [Symbol] access :read or :edit
    # @return [Array<Hyrax::WorksCountService::SearchResultForWorkCount>] a list with documents
    def search_results_with_work_count(access)
      works = search_results(access)

      works.map do |work|
        created_date = DateTime.parse(work['system_create_dtsi']).in_time_zone.strftime("%Y-%m-%d")
        SearchResultForWorkCount.new(work, created_date, 0, work['human_readable_type_tesim'][0], work['visibility_ssi'])
      end
    end

    private

      def builder(_)
        search_builder.new(context).rows(1000)
      end
  end
end
