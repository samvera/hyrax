# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaBehavior
    extend ActiveSupport::Concern

    included do
      before_action :set_latest_schema_version, only: [:edit]
    end

    private

    def set_latest_schema_version
      @latest_schema_version = Hyrax::FlexibleSchema.current_schema_id.to_f if Hyrax.config.flexible?
    end
  end
end
