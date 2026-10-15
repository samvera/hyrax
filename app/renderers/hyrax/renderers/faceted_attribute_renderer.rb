# frozen_string_literal: true
module Hyrax
  module Renderers
    class FacetedAttributeRenderer < AttributeRenderer
      private

      def li_value(value)
        link_to(ERB::Util.h(search_term(value)), search_path(value))
      end

      # The facet name and the queried value move together: the label facet
      # holds labels and the id facet holds ids, so pairing one with the other
      # would filter nothing.
      def search_path(value)
        queried = label_facet?(value) ? search_term(value) : value

        Rails.application.routes.url_helpers.search_catalog_path(
          "f[#{search_field(value)}][]": queried, locale: I18n.locale
        )
      end

      # The label facet for a controlled term, matching where the catalog
      # sidebar registers it. Linking to the id facet instead would filter
      # correctly but leave a constraint the sidebar cannot match, so one
      # concept would show as two applied filters.
      #
      # Only when that facet exists; see AttributesHelper#label_facet_registered?.
      def search_field(value)
        base = options.fetch(:search_field, field).to_s
        base = Hyrax::ControlledVocabularyFieldValues.label_prefix(base) if label_facet?(value)

        ERB::Util.h("#{base}_sim")
      end

      def label_facet?(value)
        controlled_label_for(value).present? && options.fetch(:label_facet_registered, true)
      end
    end
  end
end
