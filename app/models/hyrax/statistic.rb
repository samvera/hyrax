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

      def query_works(query)
        models = Hyrax::ModelRegistry.work_rdf_representations.map { |m| "\"#{m}\"" }
        response = Hyrax::SolrService.get(fq: "has_model_ssim:(#{models.join(' OR ')})", 'facet.field': query, 'facet.missing': true, rows: 0)
        Hash[*response['facet_counts']['facet_fields'][query]]
      end

      def work_types
        types = query_works("human_readable_type_sim")
        types['Unknown'] = types.delete(nil)
        types
      end

      def resource_types
        types = query_works("resource_type_sim")
        types['Unknown'] = types.delete(nil)
        types
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
          page_stats = Hyrax::Analytics.page_statistics(stat_cache_info[:ga_start_date], object)
          latest_zero_date = nil
          page_stats.each do |stat|
            lstat, zero_date = record_stat(object, stat, object_method, ga_key, user_id)
            stats << lstat
            latest_zero_date = [latest_zero_date, zero_date].compact.max
          end
          advance_zero_marker(object, object_method, latest_zero_date, user_id) if latest_zero_date
        end
        stats
      end

      # @return [Array(Hyrax::Statistic, Date?)] the built stat, and its date if zero-count
      def record_stat(object, stat, object_method, ga_key, user_id)
        lstat = build_for(object, date: stat[:date], object_method => stat[ga_key], user_id: user_id)
        return [lstat, nil] if stat[:date].to_date == Time.zone.today
        return [lstat, stat[:date].to_date] unless stat[ga_key].to_i.positive?

        lstat.save
        [lstat, nil]
      end

      def advance_zero_marker(object, object_method, date, user_id)
        marker = statistics_for(object).where(object_method => 0).order(date: :asc).last
        if marker
          marker.update(date: date) if date > marker.date
        else
          build_for(object, date: date, object_method => 0, user_id: user_id).save
        end
      end
    end

    def to_flot
      [self.class.convert_date(date), send(cache_column)]
    end
  end
end
