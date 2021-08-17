# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class CollectionReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        before_action :set_defaults
        layout 'hyrax/dashboard'

        def index
          @pageviews = Hyrax::Analytics.pageviews("collections")
          @downloads = Hyrax::Analytics.downloads 
          @top_collections = Hyrax::Analytics.top_pages("collections", "#{@start_date},#{@end_date}")
        end

        def show 
          @document = ::SolrDocument.find(params[:id])
          @path = collection_path(params[:id])
          if Hyrax.config.analytics_provider == 'matomo'
            @path = request.base_url + @path
          end
          @pageviews = Hyrax::Analytics.pageviews_for_url(@path)
          @uniques = Hyrax::Analytics.unique_visitors_for_url(@path)
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
