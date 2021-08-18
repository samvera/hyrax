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
          @downloads = Hyrax::Analytics.downloads("works")
          @top_works = paginate(Hyrax::Analytics.top_pages("works"), rows: 10)
          @top_downloads = paginate(Hyrax::Analytics.top_downloads("works"), rows: 10)
          models = Hyrax.config.curation_concerns.map {|m| "\"#{m.to_s}\"" }
          @works_count = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})",fl: "id").count
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
          @files = paginate(@document._source["file_set_ids_ssim"], rows: 5)
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
 
        def paginate(results_array, rows: 2)
          unless results_array.nil?
            total_pages = (results_array.size.to_f / rows.to_f).ceil
            page = request.params[:page].nil? ? 1 : request.params[:page].to_i
            current_page = page > total_pages ? total_pages : page
            Kaminari.paginate_array(results_array, total_count: results_array.size).page(current_page).per(rows)
          end
        end
        
      end
    end
  end
end
