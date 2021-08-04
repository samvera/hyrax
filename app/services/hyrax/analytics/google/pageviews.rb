module Hyrax
  module Analytics
    module Google
      module Pageviews
        extend Legato::Model

        # metrics :pageviews, :uniquePageviews
        # dimensions :pagePathLevel1

        metrics :sessions, :pageviews

        # filter(:by_index_in_path_level_1) {|page_path_level1| contains(:pagePathLevel1, 'works')}

        def self.query(profile, start_date, end_date)
          x = Pageviews.results(profile,
            :start_date => start_date,
            :end_date => end_date)
          x.count.zero? ? 0 : x.to_a.first.pageviews.to_i
        end

      end
    end
  end
end