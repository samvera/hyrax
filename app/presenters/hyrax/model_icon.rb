# frozen_string_literal: true
module Hyrax
  class ModelIcon
    def self.css_class_for(model)
      I18n.t(:"hyrax.icons.#{model.model_name.i18n_key}", default: :"hyrax.icons.default")
    end
  end
end
