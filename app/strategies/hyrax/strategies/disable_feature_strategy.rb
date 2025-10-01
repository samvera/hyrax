# frozen_string_literal: true
module Hyrax::Strategies
  class DisableFeatureStrategy < Flipflop::Strategies::AbstractStrategy
    def enabled?(feature)
      # Set batch upload to disabled
      return false if feature == :batch_upload
      # Return nil to pass through to next strategy for other features
      nil
    end
  end
end
