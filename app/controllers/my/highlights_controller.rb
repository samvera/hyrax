module My
  class HighlightsController < MyController
    def search_builder_class
      Sufia::MyHighlightsSearchBuilder
    end

    def index
      super
      @selected_tab = 'highlighted'
    end

    protected

      def search_action_url(*args)
        sufia.dashboard_highlights_url(*args)
      end

      def query_solr
        return empty_search_result if @user.trophy_works.count == 0
        super
      end

      def empty_search_result
        empty_request = {
          responseHeader: {
            status: 0,
            params: {
              wt: 'ruby',
              rows: '11',
              q: '*:*'
            }
          },
          response: {
            numFound: 0,
            start: 0,
            docs: []
          }
        }
        solr_response = Blacklight::Solr::Response.new(empty_request, {})
        docs = []
        [solr_response, docs]
      end
  end
end
