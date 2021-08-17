# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        before_action :set_defaults
        layout 'hyrax/dashboard'

        def index
          @pageviews = Hyrax::Analytics.pageviews("works")
          @downloads = Hyrax::Analytics.downloads
          @top_works = Hyrax::Analytics.top_pages("works")
          @top_downloads = Hyrax::Analytics.top_downloads
          respond_to do |format|
            format.html
            format.csv do export_data end
          end
        end

        def show 
          @document = ::SolrDocument.find(params[:id])
          @path = main_app.send("hyrax_#{@document._source['has_model_ssim'].first.underscore}s_path", params[:id]).sub('.', '/')
          if Hyrax.config.analytics_provider == 'matomo'
            @path = request.base_url + @path
          end
          @pageviews = Hyrax::Analytics.pageviews_for_url(@path)
          @uniques = Hyrax::Analytics.unique_visitors_for_url(@path)
          @downloads = Hyrax::Analytics.downloads
          @files = @document._source["file_set_ids_ssim"]
          respond_to do |format|
            format.html
            format.csv do export_data end
          end
        end

        private 

        def set_defaults
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today + 1.day
          @month_names = 12.downto(1).map { |n| DateTime::MONTHNAMES.drop(1)[(Date.today.month - n) % 12] }.reverse
        end

        def export_data
          if (params[:format_data] == 'downloads')
            send_data @downloads.to_csv, filename: "#{@start_date}-#{@end_date}-downloads.csv"
          elsif (params[:format_data] == 'pageviews')
            send_data @pageviews.to_csv, filename: "#{@start_date}-#{@end_date}-pageviews.csv"
          elsif (params[:format_data] == 'uniques')
            send_data  @uniques.to_csv, filename: "#{@start_date}-#{@end_date}-uniques.csv"
          elsif (params[:format_data] == 'top_works')
            send_data @top_works.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_works.csv"
          elsif (params[:format_data] == 'top_downloads')
            send_data @top_downloads.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_downloads.csv"
          end
        end
        
      end
    end
  end
end
