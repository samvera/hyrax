# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class AnalyticsController < ApplicationController
        include Hyrax::SingularSubresourceController
        before_action :set_months
        before_action :set_date_range
        before_action :set_document, only: [:show]
        with_themed_layout 'dashboard'

        def set_document
          @document = ::SolrDocument.find(params[:id])
        end

        def set_months
          @month_names = 12.downto(1).map { |n| DateTime::ABBR_MONTHNAMES.drop(1)[(Time.zone.today.month - n) % 12] }.reverse
        end

        def set_date_range
          @start_date = params[:start_date] || Hyrax.config.analytics_start_date
          @end_date = params[:end_date] || Time.zone.today + 1.day
        end

        def date_range
          "#{@start_date},#{@end_date}"
        end

        def paginate(results_array, rows: 10)
          return if results_array.nil?

          total_pages = (results_array.size.to_f / rows.to_f).ceil
          page = request.params[:page].nil? ? 1 : request.params[:page].to_i
          current_page = page > total_pages ? total_pages : page
          Kaminari.paginate_array(results_array, total_count: results_array.size).page(current_page).per(rows)
        end
      end
    end
  end
end
