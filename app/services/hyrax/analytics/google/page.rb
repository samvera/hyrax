module Hyrax
  module Analytics
    module Google
      module Page
        extend Legato::Model

        metrics :pageviews
        dimensions :page_path, :page_path_level1, :page_title

        filter(:collections) {|page_path_level1| contains(:pagePathLevel1, 'collections')}
        filter(:works) {|page_path_level1| contains(:pagePathLevel1, 'concern')}

        def self.collections(profile, start_date, end_date)
          x = Page.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => '-pageviews',
            :limit => 5).collections
        end

        def self.works(profile, start_date, end_date)
          x = Page.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => '-pageviews',
            :limit => 5).works
        end

      end
    end
  end
end