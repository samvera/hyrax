module CurationConcerns
  class PermissionBadge
    include ActionView::Helpers::TagHelper

    def initialize(solr_document)
      @solr_document = solr_document
    end

    # Draws a span tag with styles for a bootstrap label
    def render
      content_tag(:span, link_title, title: link_title, class: "label #{dom_label_class}")
    end

    private

      def dom_label_class
        if open_access_with_embargo?
          'label-warning'
        elsif open_access?
          'label-success'
        elsif registered?
          'label-info'
        else
          'label-danger'
        end
      end

      def link_title
        if open_access_with_embargo?
          'Open Access with Embargo'
        elsif open_access?
          'Open Access'
        elsif registered?
          I18n.translate('curation_concerns.institution_name')
        else
          'Private'
        end
      end

      def open_access_with_embargo?
        if @open_access_with_embargo.nil?
          @open_access_with_embargo = open_access? && embargo?
        end
        @open_access_with_embargo
      end

      def open_access?
        @open_access = @solr_document.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if @open_access.nil?
        @open_access
      end

      def registered?
        @registered = @solr_document.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if @registered.nil?
        @registered
      end

      def embargo?
        @solr_document.embargo_release_date.present?
      end
  end
end
