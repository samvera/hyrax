# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class CollectionReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        include Hyrax::BreadcrumbsForCollectionAnalytics
        before_action :set_defaults
        with_themed_layout 'dashboard'

        def index
          return unless Hyrax.config.analytics == true

          @pageviews = Hyrax::Analytics.pageviews('collection-page-view')
          @work_page_views = Hyrax::Analytics.pageviews('work-in-collection-view')
          @downloads = Hyrax::Analytics.downloads('work-in-collection-download')
          @top_collections = paginate(Hyrax::Analytics.top_pages('work-in-collection-view'), rows: 10)
          @top_downloads = Hyrax::Analytics.top_downloads('work-in-collection-download')
          @top_collection_pages = Hyrax::Analytics.top_pages('collection-page-view')
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
          @downloads = Hyrax::Analytics.downloads_for_collection_id(@document.id)
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
          csv_row = CSV.generate do |csv|
            # insert the headers
            csv << ["Name", "ID", "Collection Page Views", "View of Works In Collection", "Downloads of Works In Collection"]
            # run all over the transactions
            @top_collections.each do |collection|
              # Check to make sure this collection exists as a Solr document
              document = ::SolrDocument.find(collection[0]) rescue document = nil
              if document 
                # Look for a matching collection ID in the top downloads report (to get the downloads count)
                match = @top_downloads.detect {|a,b| a == collection[0]}
                # each of transactions is inserted into the csv file
                csv << [document, collection[0], collection[1], match[1] || 0]
              end
            end
          end
          send_data csv_row, filename: "#{@start_date}-#{@end_date}-collections.csv"
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
