# frozen_string_literal: true

module Hyrax
  module FlexibleCatalogBehavior
    extend ActiveSupport::Concern

    class_methods do
      def load_flexible_schema
        previous_profile, current_profile = Hyrax::FlexibleSchema.order("created_at asc").last(2).map(&:profile)
        return if previous_profile.blank? && current_profile.blank?

        Hyrax::FlexibleCatalogConfigBuilder.new(blacklight_config).apply(previous_profile, current_profile)
      end
    end

    def initialize
      self.class.load_flexible_schema
      super
    end

    # Hook to allow optional rendering at the app level
    def render_optionally?
      true
    end
  end
end
