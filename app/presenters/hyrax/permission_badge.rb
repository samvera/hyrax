# frozen_string_literal: true
module Hyrax
  class PermissionBadge
    include ActionView::Helpers::TagHelper

    VISIBILITY_LABEL_CLASS = {
      authenticated: "label-info",
      embargo: "label-warning",
      lease: "label-warning",
      open: "label-success",
      restricted: "label-danger"
    }.freeze

    # @param visibility [String] the current visibility
    def initialize(visibility)
      @visibility = visibility
    end

    # Draws a span tag with styles for a bootstrap label
    def render
      tag.span(text, class: "label #{dom_label_class}")
    end

    private

    def dom_label_class
      VISIBILITY_LABEL_CLASS.fetch(@visibility&.to_sym, 'label-info')
    end

    def text
      if registered?
        Institution.name
      else
        visibility_key = @visibility || 'unknown'
        I18n.t("hyrax.visibility.#{visibility_key}.text")
      end
    end

    def registered?
      @visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end
end
