# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < ApplicationController
        layout 'hyrax/dashboard'

        def index
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today
          @last_twelve_months = Hyrax::Analytics.works_pageviews_monthly("month", "last12")
          @works = Hyrax::Analytics.top_works("range", "#{@start_date},#{@end_date}")
        end

        def show; end
      end
    end
  end
end
