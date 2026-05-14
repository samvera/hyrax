# frozen_string_literal: true
module Hyrax
  module Renderers
    # This is used by PresentsAttributes to show licenses
    #   e.g.: presenter.attribute_to_html(:rights_statement, render_as: :rights_statement)
    class RightsStatementAttributeRenderer < AttributeRenderer
      private

      ##
      # Special treatment for license/rights. A URL from the Hyrax gem's
      # `config/hyrax.rb` is stored in the descMetadata of the
      # curation_concern. If the stored value is an absolute http/https URI,
      # render it as a link with the authority's label; otherwise render the
      # value as plain text to avoid emitting unsafe href values (e.g.
      # `javascript:`) or broken links for free-text values.
      def attribute_value_to_html(value)
        if Hyrax::AuthorityRenderingHelper.linkable_uri?(value)
          label = Hyrax.config.rights_statement_service_class.new.label(value) { value }
          %(<a href="#{ERB::Util.h(value)}" target="_blank" rel="noopener noreferrer">#{ERB::Util.h(label)}</a>)
        else
          ERB::Util.h(value)
        end
      end
    end
  end
end
