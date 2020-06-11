# frozen_string_literal: true
module Hyrax
  # Overrides of methods defined by the Blacklight gem.
  module BlacklightOverride
    def application_name
      t('hyrax.product_name', default: super)
    end
  end
end
