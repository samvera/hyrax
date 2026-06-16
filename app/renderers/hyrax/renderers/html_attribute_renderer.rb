# frozen_string_literal: true

module Hyrax
  module Renderers
    ##
    # Renders an attribute whose value is stored as HTML markup (for example,
    # the output of a rich-text / WYSIWYG editor field) as *sanitized* HTML.
    #
    # Selected by setting `render_as: :html` on the attribute, e.g. from a
    # flexible-metadata profile:
    #
    #     my_field:
    #       form:
    #         input_type: rich_text
    #       view:
    #         render_as: html
    #
    # Unlike the default {AttributeRenderer}, which HTML-escapes values, this
    # renderer passes the stored markup through `ActionView`'s allow-list
    # `sanitize` helper so a known-safe subset of tags/attributes renders while
    # scripts, event handlers, and unknown tags are stripped. The renderer does
    # not depend on any markdown engine.
    class HtmlAttributeRenderer < AttributeRenderer
      include ActionView::Helpers::SanitizeHelper

      # Inline + block tags appropriate for narrative rich text. Intentionally
      # excludes anything that can execute or load remote content (script,
      # iframe, object, style, img with onerror, etc.).
      ALLOWED_TAGS = %w[
        p br span div
        b strong i em u s strike sub sup
        a
        ul ol li
        blockquote pre code
        h1 h2 h3 h4 h5 h6
        hr
        table thead tbody tr th td
      ].freeze

      ALLOWED_ATTRIBUTES = %w[href title target rel start].freeze

      private

      # Override the base renderer's escaping behavior: render the stored markup
      # as sanitized HTML instead of escaping it.
      def li_value(value)
        sanitize(value.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
      end
    end
  end
end
