# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < AnalyticsController
        include Hyrax::BreadcrumbsForWorksAnalytics
        before_action :authenticate_user!

        def index
          return unless Hyrax.config.analytics_reporting?

          @accessible_works ||= accessible_works
          @accessible_file_sets ||= accessible_file_sets
          @works_count = @accessible_works.count
          @top_works = paginate(top_works_list, rows: 10)
          @top_file_set_downloads = paginate(top_files_list, rows: 10)

          @pageviews = Hyrax::Analytics.daily_events('work-view'), @downloads = Hyrax::Analytics.daily_events('file-set-download') if current_user.ability.admin?

          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view')
          @uniques = Hyrax::Analytics.unique_visitors_for_id(@document.id)
          @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file_set_in_work_download')
          @files = paginate(@document._source["member_ids_ssim"], rows: 5)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

  private

        def accessible_works
          models = Hyrax::ModelRegistry.work_rdf_representations.map { |m| "\"#{m}\"" }
          if current_user.ability.admin?
            Hyrax::SolrService.query("has_model_ssim:(#{models.join(' OR ')})",
              fl: 'title_tesim, id, member_of_collections',
              rows: 50_000)
          else
            Hyrax::SolrService.query(
              "edit_access_person_ssim:#{current_user} AND has_model_ssim:(#{models.join(' OR ')})",
              fl: 'title_tesim, id, member_of_collections',
              rows: 50_000
            )
          end
        end

        def accessible_file_sets
          file_set_model_clause = "has_model_ssim:\"#{Hyrax::ModelRegistry.file_set_rdf_representations.join('" OR "')}\""
          if current_user.ability.admin?
            Hyrax::SolrService.query(
              file_set_model_clause,
              fl: 'title_tesim, id',
              rows: 50_000
            )
          else
            Hyrax::SolrService.query(
              "edit_access_person_ssim:#{current_user} AND #{file_set_model_clause}",
              fl: 'title_tesim, id',
              rows: 50_000
            )
          end
        end

        def top_analytics_works
          @top_analytics_works ||= Hyrax::Analytics.top_events('work-view', date_range)
        end

        def top_analytics_downloads
          @top_analytics_downloads ||= Hyrax::Analytics.top_events('file-set-in-work-download', date_range)
        end

        def top_analytics_file_sets
          @top_analytics_file_sets ||= Hyrax::Analytics.top_events('file-set-download', date_range)
        end

        def top_works_list
          list = []
          top_analytics_works
          top_analytics_downloads
          @accessible_works.each do |doc|
            views_match = @top_analytics_works.detect { |id, _count| id == doc["id"] }
            @view_count = views_match ? views_match[1] : 0
            downloads_match = @top_analytics_downloads.detect { |id, _count| id == doc["id"] }
            @download_count = downloads_match ? downloads_match[1] : 0
            list.push([doc["id"], doc["title_tesim"].join(''), @view_count, @download_count, doc["member_of_collections"]])
          end
          list.sort_by { |l| -l[2] }
        end

        def top_files_list
          list = []
          top_analytics_file_sets
          @accessible_file_sets.each do |doc|
            downloads_match = @top_analytics_file_sets.detect { |id, _count| id == doc["id"] }
            @download_count = downloads_match ? downloads_match[1] : 0
            list.push([doc["id"], doc["title_tesim"].join(''), @download_count]) if doc["title_tesim"].present?
          end
          list.sort_by { |l| -l[2] }
        end

        def export_data
          data = top_works_list
          csv_row = CSV.generate do |csv|
            csv << ["Name", "ID", "Work Page Views", "Total Downloads of File Sets In Work", "Collections"]
            data.each do |d|
              csv << [d[0], d[1], d[2], d[3], d[4]]
            end
          end
          send_data csv_row, filename: "#{params[:start_date]}-#{params[:end_date]}-works.csv"
        end
      end
    end
  end
end
