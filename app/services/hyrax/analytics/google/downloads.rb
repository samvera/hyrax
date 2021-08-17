module Hyrax
  module Analytics
    module Google
      module Downloads
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_label

        filter :for_file, &->(file) { contains(:eventLabel, file) }

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.totalEvents.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end

        def self.file_downloads(profile, start_date, end_date, file)
          results = Downloads.results(profile,
            :start_date => start_date,
            :end_date => end_date).for_file(file)
          results.first['totalEvents'].to_i
        end
        
        def self.all(profile, start_date, end_date)
          response = Downloads.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => "-totalEvents")
          results_array(response)
        end

        def self.collections(profile, start_date, end_date)
          response = Downloads.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => "-totalEvents")
          results_array(response)
        end

        def self.works(profile, start_date, end_date)
          response = Downloads.results(profile,
            :start_date => start_date,
            :end_date => end_date,
            :sort => "-totalEvents")
          results_array(response)
        end

      end
    end
  end
end