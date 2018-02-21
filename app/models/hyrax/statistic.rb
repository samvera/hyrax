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
        profile.hyrax__pageview(sort: 'date', start_date: start_date).for_path(path)
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
          if stat_cache_info[:ga_start_date] < Time.zone.today && Hyrax.config.analytics.present?
            ga_stats = remote_stats(stat_cache_info[:ga_start_date], object, ga_key)
            ga_stats.each do |stat|
              lstat = build_for(object, date: stat[:date], object_method => stat[ga_key], user_id: user_id)
              lstat.save unless Date.parse(stat[:date]) == Time.zone.today
              stats << lstat
            end
          end
          stats
        end

        # This is the switch between the new and old analytics back-end. We can remove it in the future if both the...
        # DB write (analytics caching) and Legato stuff are superceded by new code elsewhere.
        # This means (for now at least), new analytics classes need to return data as arrays of OpenStructs or...
        # hashes (keyed with symbols or indifferent access) in a way that is still compatible with the existing...
        # keys used in `combined_stats` above, namely (where `stat` is a one of the returned rows in the array)...
        # stat[:totalevents] and stat[:pageviews]
        #
        # pageview sample data row:
        # <OpenStruct date="20180201", pageviews="1">
        #
        # downloads sample data row (note only date/totalEvents used for DB write in `combined_stats`):
        # <OpenStruct eventCategory="Files", eventAction="Downloaded", eventLabel="j67313767", date="20180212", totalEvents="1">
        #
        # TODO: A new critical requirement requires "unique visitors", what does that look like? Legato can't do it:
        # https://github.com/tpitale/legato#session-level-segments
        #
        def remote_stats(start_date, object, _event_type)
          # right now event_type is either `:pageviews` or `:totalEvents` (meaning downloads)
          # as in "old" ga_statistics, pageviews could be the default where required

          case Hyrax.config.analytics
          when 'google' # rubocop:disable Lint/EmptyWhen
            # TODO: if - else on event_type, calling e.g. Hyrax::Analytic::GoogleAnalytics.pageviews
          when 'matomo' # rubocop:disable Lint/EmptyWhen
            # TODO: if - else on event_type, calling e.g. Hyrax::Analytic::Matomo.pageviews
          else
            # the old Legato call, with event_type essentially set by overriding `ga_statistics` (`hyrax__pageview` etc)
            ga_statistics(start_date, object)
          end
        end
    end

    def to_flot
      [self.class.convert_date(date), send(cache_column)]
    end
  end
end
