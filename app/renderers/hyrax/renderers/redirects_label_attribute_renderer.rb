# frozen_string_literal: true

module Hyrax
  module Renderers
    # Renders each redirect path as a clickable link. The link text is the full
    # absolute URL (host + path); the href is the path alone, which the browser
    # resolves against the current document's host. Used on show pages via the
    # `redirects` schema's `render_as: redirects_label` view option.
    class RedirectsLabelAttributeRenderer < AttributeRenderer
      private

      def li_value(value)
        path = value.to_s
        return ERB::Util.h(path) if path.blank?

        display = base_url.present? ? "#{base_url}#{path}" : path
        link_to(ERB::Util.h(display), path)
      end

      def base_url
        options[:base_url].to_s.sub(%r{/+\z}, '')
      end
    end
  end
end
