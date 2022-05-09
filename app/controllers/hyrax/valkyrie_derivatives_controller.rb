# frozen_string_literal: true
module Hyrax
  class ValkyrieDerivativesController < ValkyrieFileController
    def show
      super
    end

    def storage_adapter
      Hyrax.config.derivatives_storage_adapter
    end
  end
end
