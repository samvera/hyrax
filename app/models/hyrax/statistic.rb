# frozen_string_literal: true
module Hyrax
  class Statistic < ActiveRecord::Base
    self.abstract_class = true

    class_attribute :cache_column, :event_type

    class << self
      include ActionDispatch::Routing::PolymorphicRoutes
      include Rails.application.routes.url_helpers

      def statistics_for(object)
        where(filter(object))
      end

      def build_for(object, attrs)
        new attrs.merge(filter(object))
      end

      def convert_date(date_time)
        date_time.to_datetime.to_i * 1000
      end

      def statistics(object, start_date, user_id = nil)
        combined_stats object, start_date, cache_column, event_type, user_id
      end

      # Hyrax::Download is sent to Hyrax::Analytics.profile as #hyrax__download
      # see Legato::ProfileMethods.method_name_from_klass
      def ga_statistics(start_date, object)
        path = polymorphic_path(object)
        profile = Hyrax::Analytics.profile
        unless profile
          Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
          return []
        end
        profile.hyrax__analytics__google__pageviews(sort: 'date',
                                                    start_date: start_date,
                                                    end_date: Date.yesterday,
                                                    limit: 10_000)
               .for_path(path)
      end

      def query_works(query)
        models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
        ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", fl: query, rows: 100_000)
      end

      def work_types
        results = query_works("human_readable_type_tesim")
        results.group_by { |result| result['human_readable_type_tesim'].join('') }.transform_values(&:count)
      end

      def resource_types
        results = query_works("resource_type_tesim")
        resource_types = []
        results.each do |y|
          if y["resource_type_tesim"].nil? || (y["resource_type_tesim"] == [""])
            resource_types.push("Unknown")
          elsif y["resource_type_tesim"].count > 1
            y["resource_type_tesim"].each do |t|
              resource_types.push(t)
            end
          else
            resource_types.push(y["resource_type_tesim"].join(""))
          end
        end
        resource_types.group_by { |rt| rt }.transform_values(&:count)
      end

      private

      def cached_stats(object, start_date, _method)
        stats = statistics_for(object).order(date: :asc)
        ga_start_date = stats.any? ? stats[stats.size - 1].date + 1.day : start_date.to_date
        { ga_start_date: ga_start_date, cached_stats: stats.to_a }
      end

      def combined_stats(object, start_date, object_method, ga_key, user_id = nil)
        stat_cache_info = cached_stats(object, start_date, object_method)
        stats = stat_cache_info[:cached_stats]
        if stat_cache_info[:ga_start_date] < Time.zone.today
          ga_stats = ga_statistics(stat_cache_info[:ga_start_date], object)
          ga_stats.each do |stat|
            lstat = build_for(object, date: stat[:date], object_method => stat[ga_key], user_id: user_id)
            lstat.save unless Date.parse(stat[:date]) == Time.zone.today
            stats << lstat
          end
        end
        stats
      end
    end

    def to_flot
      [self.class.convert_date(date), send(cache_column)]
    end
  end
end
