# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        include Hyrax::BreadcrumbsForWorksAnalytics
        before_action :set_defaults
        before_action :set_document, only: [:show]
        with_themed_layout 'dashboard'

        def index
          return unless Hyrax.config.analytics == true

          @pageviews = Hyrax::Analytics.pageviews('work-view')
          @downloads = Hyrax::Analytics.downloads('file-set-download')
          @all_top_works = Hyrax::Analytics.top_pages('work-view', "#{@start_date},#{@end_date}")
          @top_works = paginate(@all_top_works, rows: 10)
          @top_downloads = Hyrax::Analytics.top_downloads('file-set-in-work-download', "#{@start_date},#{@end_date}")
          @top_file_set_downloads = paginate(Hyrax::Analytics.top_downloads('file-set-download', "#{@start_date},#{@end_date}"), rows: 10)
          models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
          @works_count = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", fl: "id").count
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          @pageviews = Hyrax::Analytics.pageviews_for_id(@document.id)
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id)
          @downloads = Hyrax::Analytics.downloads_for_id(@document.id)
          @files = paginate(@document._source["file_set_ids_ssim"], rows: 5)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

        def set_document
          @document = ::SolrDocument.find(params[:id])
        end

        def set_defaults
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today + 1.day
          @month_names = 12.downto(1).map { |n| DateTime::MONTHNAMES.drop(1)[(Time.zone.today.month - n) % 12] }.reverse
        end

        def export_data
          csv_row = CSV.generate do |csv|
            csv << ["Name", "ID", "Work Page Views", "Total Downloads of File Sets In Work", "Collections"]
            @all_top_works.each do |work|
              document = begin
                           ::SolrDocument.find(work[0])
                         rescue
                           document = nil
                         end
              title = document ? document : "Work deleted"
              collections = document ? document.member_of_collections : nil
              match = @top_downloads.detect { |a, _b| a == work[0] }
              download_count = match ? match[1] : 0
              collections = 
              csv << [title, work[0], work[1], download_count, collections ]
            end
          end
          send_data csv_row, filename: "#{@start_date}-#{@end_date}-works.csv"
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
