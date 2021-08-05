# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class CollectionReportsController < ApplicationController
        layout 'hyrax/dashboard'

        def index
          @start_date = params[:start_date] || Date.today - 1.month
          @end_date = params[:end_date] || Date.today
          @last_twelve_months = Hyrax::Analytics.collections_pageviews_monthly("month", "last12")
          @collections = Hyrax::Analytics.top_collections("range", "#{@start_date},#{@end_date}")
        end

        def show; end
      end
    end
  end
end
