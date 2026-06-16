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

      # Render the stored markup as sanitized HTML.
      #
      # We override +attribute_value_to_html+ (not just +li_value+) so this
      # renderer fully owns its output and is unaffected by any markdown/escaping
      # decorator an application may prepend onto the base AttributeRenderer
      # (e.g. Hyku's `treat_some_user_inputs_as_markdown` feature flag wraps
      # values in `markdown()`). Sanitized rich text should render identically
      # regardless of that flag.
      def attribute_value_to_html(value)
        sanitized = sanitize(value.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
        return sanitized if microdata_value_attributes(field).blank?

        # Return the assembled span as a plain string (matching the base
        # AttributeRenderer#attribute_value_to_html contract); the caller in
        # #render applies html_safe once to the full markup. `sanitized` is
        # already allow-list sanitized, so no unsafe content is reintroduced.
        "<span#{html_attributes(microdata_value_attributes(field))}>#{sanitized}</span>"
      end

      # Kept for callers/subclasses that invoke +li_value+ directly; mirrors the
      # sanitizing behavior above.
      def li_value(value)
        sanitize(value.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
      end
    end
  end
end
