# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class CollectionReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        before_action :set_defaults
        layout 'hyrax/dashboard'

        def index
          return unless Hyrax.config.analytics == true

          @pageviews = Hyrax::Analytics.pageviews("collections")
          @downloads = Hyrax::Analytics.downloads("collections")
          @top_collections = paginate(Hyrax::Analytics.top_pages("collections"), rows: 10)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          @document = ::SolrDocument.find(params[:id])
          @path = collection_path(params[:id])
          return unless Hyrax.config.analytics == true

          @path = request.base_url + @path if Hyrax.config.analytics_provider == 'matomo'
          @pageviews = Hyrax::Analytics.pageviews_for_url(@path)
          @uniques = Hyrax::Analytics.unique_visitors_for_url(@path)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

        def set_defaults
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today + 1.day
          @month_names = 12.downto(1).map { |n| DateTime::MONTHNAMES.drop(1)[(Time.zone.today.month - n) % 12] }.reverse
        end

        def export_data
          if params[:format_data] == 'downloads'
            send_data @downloads.to_csv, filename: "#{@start_date}-#{@end_date}-downloads.csv"
          elsif params[:format_data] == 'pageviews'
            send_data @pageviews.to_csv, filename: "#{@start_date}-#{@end_date}-pageviews.csv"
          elsif params[:format_data] == 'uniques'
            send_data @uniques.to_csv, filename: "#{@start_date}-#{@end_date}-uniques.csv"
          elsif params[:format_data] == 'top_collections'
            send_data @top_collections.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_collections.csv"
          elsif params[:format_data] == 'top_downloads'
            send_data @top_downloads.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_downloads.csv"
          end
        end

        def paginate(results_array, rows: 2)
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
