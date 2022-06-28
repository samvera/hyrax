# frozen_string_literal: true
module Hyrax
  module Renderers
    class ExternalLinkAttributeRenderer < AttributeRenderer
      private

      def li_value(value)
        auto_link(value) do |link|
          "<span class='fa fa-external-link'></span>&nbsp;#{link}"
        end
      end
    end
  end
end
