# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < ApplicationController
        layout 'hyrax/dashboard'

        def index
          @start_date = params[:start_date] || Date.today - 1.month
          @end_date = params[:end_date] || Date.today 
          @last_twelve_months = Hyrax::Analytics.pageviews_monthly("month", "last12")
        end

        def show; end
      end
    end
  end
end
