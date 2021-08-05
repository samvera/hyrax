module Hyrax
  module Analytics
    module Google
      module Pageviews
        extend Legato::Model

        # metrics :pageviews, :uniquePageviews
        # dimensions :pagePathLevel1

        metrics :sessions, :pageviews
        dimensions :page_path, :page_path_level1

        filter(:collections) {|page_path_level1| contains(:pagePathLevel1, 'collections')}
        filter(:works) {|page_path_level1| contains(:pagePathLevel1, 'concern')}

        def self.query(profile, start_date, end_date)
          x = Pageviews.results(profile,
            :start_date => start_date,
            :end_date => end_date)
        x.count.zero? ? 0 : x.to_a.first.pageviews.to_i
      end

        def self.collections(profile, start_date, end_date)
          pageview_counts = []
            x = Pageviews.results(profile,
              :start_date => start_date,
              :end_date => end_date).collections.each do |page|
                pageview_counts.push(page.pageviews.to_i)
              end
              x = pageview_counts.sum 
        end

        def self.works(profile, start_date, end_date)
          pageview_counts = []
          Pageviews.results(profile,
            :start_date => start_date,
            :end_date => end_date).works.each do |page| 
              pageview_counts.push(page.pageviews.to_i)
            end
            x = pageview_counts.sum 
        end

      end
    end
  end
end