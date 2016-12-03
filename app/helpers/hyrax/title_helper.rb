module Hyrax::TitleHelper
  def application_name
    t('hyrax.product_name', default: super)
  end

  def construct_page_title(*elements)
    (elements.flatten.compact + [application_name]).join(' // ')
  end

  def curation_concern_page_title(curation_concern)
    if curation_concern.persisted?
      construct_page_title(curation_concern.to_s, "#{curation_concern.human_readable_type} [#{curation_concern.to_param}]")
    else
      construct_page_title("New #{curation_concern.human_readable_type}")
    end
  end

  def default_page_title
    text = controller_name.singularize.titleize
    text = "#{action_name.titleize} " + text if action_name
    construct_page_title(text)
  end
end
