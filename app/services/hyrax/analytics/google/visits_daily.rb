# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module VisitsDaily
        extend Legato::Model

        dimensions :date, :user_type
        metrics :sessions

        filter(:returning) { |_user_type| matches(:userType, 'Returning Visitor') }
        filter(:new_visit) { |_user_type| matches(:userType, 'New Visitor') }

        def self.new_visits(profile, start_date, end_date)
          response = VisitsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).new_visit.to_a
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.return_visits(profile, start_date, end_date)
          response = VisitsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).returning.to_a
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.results_array(response, dates)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.sessions.to_i])
          end
          new_results = []
          dates.each do |date|
            match = results.detect { |a, _b| a == date }
            if match
              new_results.push(match)
            else
              new_results.push([date, 0])
            end
          end
          Hyrax::Analytics::Results.new(new_results)
        end
      end
    end
  end
end
