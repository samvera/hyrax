module Hyrax
  class PermissionBadge
    include ActionView::Helpers::TagHelper

    # @param visibility_or_document [String,#visibility] the current visibility or an object
    #                                                    that has a method returning visibility
    def initialize(visibility_or_document)
      self.visibility = visibility_or_document
    end

    # Draws a span tag with styles for a bootstrap label
    def render
      content_tag(:span, text, class: "label #{dom_label_class}")
    end

    private

      def visibility=(visibility_or_document)
        @visibility = if visibility_or_document.respond_to?(:visibility)
                        Deprecation.warn(self, "PermissionBadge#visibility= no longer accepts a document, pass the visibility string instead. This will be removed in Hyrax 2.0")
                        visibility_or_document.visibility
                      else
                        visibility_or_document
                      end
      end

      def dom_label_class
        I18n.t("hyrax.visibility.#{@visibility}.class")
      end

      def text
        if registered?
          Institution.name
        else
          I18n.t("hyrax.visibility.#{@visibility}.text")
        end
      end

      def registered?
        @visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
  end
end
