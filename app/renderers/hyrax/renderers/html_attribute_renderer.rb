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
        sanitized = sanitize_rich_text(value.to_s)
        return sanitized if microdata_value_attributes(field).blank?

        # Wrap in a block-level <div> (not <span>) when carrying microdata: the
        # allow-list permits block elements (p, div, table, ...) and nesting
        # those inside a <span> is invalid HTML. Returned as a plain string per
        # the base AttributeRenderer#attribute_value_to_html contract; #render
        # applies html_safe once to the full markup. `sanitized` is already
        # allow-list sanitized, so no unsafe content is reintroduced.
        "<div#{html_attributes(microdata_value_attributes(field))}>#{sanitized}</div>"
      end

      # Kept for callers/subclasses that invoke +li_value+ directly; mirrors the
      # sanitizing behavior above.
      def li_value(value)
        sanitize_rich_text(value.to_s)
      end

      # Allow-list sanitize, then ensure any author-supplied `target="_blank"`
      # link also carries `rel="noopener noreferrer"`. Without it, the opened
      # page can reach back through `window.opener` (reverse tabnabbing); Hyrax
      # adds this rel consistently elsewhere (e.g. LicenseAttributeRenderer).
      def sanitize_rich_text(value)
        harden_blank_target_links(sanitize(value, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES))
      end

      def harden_blank_target_links(html)
        return html unless html.to_s.include?('target')

        fragment = Nokogiri::HTML.fragment(html)
        fragment.css('a[target="_blank"]').each do |anchor|
          anchor['rel'] = (anchor['rel'].to_s.split + %w[noopener noreferrer]).uniq.join(' ')
        end
        # Plain String per the attribute_value_to_html contract; #render applies
        # html_safe once. The content is already allow-list sanitized above.
        fragment.to_html
      end
    end
  end
end
