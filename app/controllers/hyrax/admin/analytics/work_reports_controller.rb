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
          @top_works = Hyrax::Analytics.top_pages("works", "#{@start_date},#{@end_date}")
          @top_downloads = Hyrax::Analytics.top_downloads("#{@start_date},#{@end_date}")
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
        end

        private 

        def set_defaults
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today + 1.day
          @month_names = 12.downto(1).map { |n| DateTime::MONTHNAMES.drop(1)[(Date.today.month - n) % 12] }.reverse
        end

      end
    end
  end
end
