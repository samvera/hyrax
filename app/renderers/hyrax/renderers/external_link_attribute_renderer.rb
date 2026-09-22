# frozen_string_literal: true
module Hyrax
  module Renderers
    class ExternalLinkAttributeRenderer < AttributeRenderer
      private

      def li_value(value)
        label = controlled_label_for(value)
        return auto_link_value(value) if label.blank?

        safe_join([tag.span(class: 'fa fa-external-link'), ' ',
                   link_to(label, value, target: '_blank', rel: 'noopener noreferrer')])
      end

      def auto_link_value(value)
        auto_link(value, html: { target: "_blank", rel: "noopener noreferrer" }) do |link|
          "<span class='fa fa-external-link'></span>&nbsp;#{link}"
        end
      end
    end
  end
end
