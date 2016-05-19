module Sufia
  class CollectionPresenter < CurationConcerns::CollectionPresenter
    delegate :resource_type, :based_near, :related_url, :identifier, to: :solr_document

    # Terms is the list of fields displayed by app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:title, :total_items, :size, :resource_type, :description, :creator,
       :contributor, :keyword, :rights, :publisher, :date_created, :subject,
       :language, :identifier, :based_near, :related_url]
    end

    def terms_with_values
      self.class.terms.select { |t| self[t].present? }
    end

    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        solr_document.send key
      end
    end
  end
end
