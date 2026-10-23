# frozen_string_literal: true

module Hyrax
  module FlexibleCatalogBehavior
    extend ActiveSupport::Concern

    BASELINE_LOCK = Monitor.new

    class_methods do
      def load_flexible_schema
        previous_profile, current_profile = Hyrax::FlexibleSchema.order("created_at asc").last(2).map(&:profile)
        return blacklight_config if previous_profile.blank? && current_profile.blank?

        self.blacklight_config = Hyrax::FlexibleCatalogConfigBuilder.new(flexible_baseline_config.deep_copy)
                                                                    .apply(previous_profile, current_profile, earlier_properties: Hyrax::FlexibleSchema.property_history)
      end

      def blacklight_config
        @blacklight_config ||= if superclass.respond_to?(:flexible_baseline_config)
                                 superclass.flexible_baseline_config.build(self)
                               else
                                 super
                               end
      end

      ##
      # The controller's configuration as it stood before any profile was loaded. Every load builds
      # onto a copy of it, and a subclass's configuration starts from its superclass's. Captured once,
      # on the first load or the first subclass configuration. To change the configuration once
      # requests have started, change this rather than `blacklight_config`, which the next load
      # replaces.
      #
      # @return [Blacklight::Configuration]
      def flexible_baseline_config
        @flexible_baseline_config || BASELINE_LOCK.synchronize { @flexible_baseline_config ||= blacklight_config.deep_copy }
      end

      ##
      # Forgets the baseline, so the next load captures `blacklight_config` as it is then. Use it only
      # when no profile has been applied to that configuration, such as after replacing it with a
      # fresh one; otherwise the new baseline carries the last load's profile.
      def reset_flexible_baseline!
        BASELINE_LOCK.synchronize { @flexible_baseline_config = nil }
      end
    end

    def blacklight_config
      @blacklight_config ||= self.class.load_flexible_schema.deep_copy
    end

    # Hook to allow optional rendering at the app level
    def render_optionally?
      true
    end
  end
end
