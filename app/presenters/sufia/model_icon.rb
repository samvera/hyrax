module Sufia
  class ModelIcon
    def self.css_class_for(model)
      I18n.t(:"sufia.icons.#{model.model_name.i18n_key}", default: :"sufia.icons.default")
    end
  end
end
