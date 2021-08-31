# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < AnalyticsController
        def index
          return unless Hyrax.config.analytics == true

          @pageviews = Hyrax::Analytics.daily_events('work-view')
          @downloads = Hyrax::Analytics.daily_events('file-set-download')
          @all_top_works = Hyrax::Analytics.top_events('work-view', date_range)
          @top_works = paginate(@all_top_works, rows: 10)
          @top_downloads = Hyrax::Analytics.top_events('file-set-in-work-download', date_range)
          @top_file_set_downloads = paginate(Hyrax::Analytics.top_events('file-set-download', date_range), rows: 10)
          models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
          @works_count = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", fl: "id").count
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view')
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id)
          @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file_set_in_work_download')
          @files = paginate(@document._source["file_set_ids_ssim"], rows: 5)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

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
      end
    end
  end
end
