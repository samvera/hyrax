module Sufia
  module AbilityHelper
    def visibility_options(variant)
      options = [
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      ]
      case variant
      when :restrict
        options.delete_at(0)
        options.reverse!
      when :loosen
        options.delete_at(2)
      end
      options.map { |value| [visibility_text(value), value] }
    end

    def visibility_badge(value)
      klass = t("sufia.visibility.#{value}.class", default: 'label-info')
      content_tag :span, visibility_text(value), class: "label #{klass}"
    end

    private

      def visibility_text(value)
        t("sufia.visibility.#{value}.text", default: value)
      end
  end
end
