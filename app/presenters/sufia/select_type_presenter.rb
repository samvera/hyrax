module Sufia
  class SelectTypePresenter
    def initialize(concern)
      @concern = concern
    end

    attr_reader :concern

    def icon_class
      ModelIcon.css_class_for(concern)
    end

    def description
      translate('description')
    end

    def name
      translate('name')
    end

    private

      def object_name
        @object_name ||= concern.model_name.i18n_key
      end

      def translate(key)
        defaults = []
        defaults << :"sufia.select_type.#{object_name}.#{key}"
        defaults << :"sufia.select_type.#{key}"
        defaults << ''
        I18n.t(defaults.shift, default: defaults)
      end
  end
end
