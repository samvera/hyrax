module CurationConcerns::RelatedResourceHelper

  # Generates the appropriate name for including in th link to a related resource
  # Primarily meant for use with CurationConcerns::LinkedResource objects, but can be used with anything that responds to .url and .title
  def related_resource_link_name(linked_resource)
    if linked_resource.title && !linked_resource.title.empty?
      raw(linked_resource.title.first + "<span class='secondary'>#{linked_resource.url}</span>")
    else
      linked_resource.url
    end
  end

end