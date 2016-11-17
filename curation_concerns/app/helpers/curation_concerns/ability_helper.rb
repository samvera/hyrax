module CurationConcerns
  module AbilityHelper
    # Returns true if can create at least one type of work
    def can_ever_create_works?
      can = false
      CurationConcerns.config.curation_concerns.each do |curation_concern_type|
        break if can
        can = can?(:create, curation_concern_type)
      end
      can
    end

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
      klass = t("curation_concerns.visibility.#{value}.class", default: 'label-info')
      content_tag :span, visibility_text(value), class: "label #{klass}"
    end

    private

      def visibility_text(value)
        t("curation_concerns.visibility.#{value}.text", default: value)
      end
  end
end
