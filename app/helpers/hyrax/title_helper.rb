# frozen_string_literal: true

module Hyrax::TitleHelper
  def application_name
    t('hyrax.product_name', default: super)
  end

  def construct_page_title(*elements)
    (elements.flatten.compact + [application_name]).join(' // ')
  end

  ##
  # @deprecated
  def curation_concern_page_title(curation_concern)
    Deprecation.warn 'The curation_concern_page_title helper will be removed in Hyrax 4.0.' \
                     "\n\tUse title_presenter(curation_concern).page_title instead."
    title_presenter(curation_concern).page_title
  end

  def default_page_title
    text = controller_name.singularize.titleize
    text = "#{action_name.titleize} " + text if action_name
    construct_page_title(text)
  end

  def title_presenter(resource)
    Hyrax::PageTitleDecorator.new(resource)
  end
end
