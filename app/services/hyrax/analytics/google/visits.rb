module Hyrax
  module Analytics
    module Google
      module Visits
        extend Legato::Model
        # metrics :visitors, :new_visits
        # dimensions :session_count, :date
        dimensions :user_type
        metrics :sessions

        def self.new_visits(profile, start_date, end_date)
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a
          x.first.sessions.to_i
        end

        def self.return_visits(profile, start_date, end_date)
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a 
          x.last.sessions.to_i
        end

        def self.total_visits(profile, start_date, end_date)
          x = Visits.results(profile,
            :start_date => start_date,
            :end_date => end_date).to_a
          new_visits = x.first.sessions.to_i 
          returning_visits = x.last.sessions.to_i 
          new_visits + returning_visits
        end
        
      end
    end
  end
end

