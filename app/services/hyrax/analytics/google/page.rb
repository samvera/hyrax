module Hyrax
  module Analytics
    module Google
      module Page
        extend Legato::Model

        metrics :pageviews
        dimensions :page_path, :page_path_level1, :page_title

        filter(:collections) {|page_path_level1| contains(:pagePathLevel1, 'collections')}
        filter(:works) {|page_path_level1| contains(:pagePathLevel1, 'concern')}

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.pageviews.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end

        def self.collections(profile, start_date, end_date)
          response = Page.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => '-pageviews').collections
        end

        def self.works(profile, start_date, end_date)
          response = Page.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => '-pageviews').works
        end
      

      end
    end
  end
end