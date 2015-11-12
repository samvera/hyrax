module Sufia
  class CollectionPresenter < CurationConcerns::CollectionPresenter
    include ActionView::Helpers::NumberHelper

    # TODO: Move date_created to CurationConcerns
    delegate :date_created, to: :solr_document

    # Terms is the list of fields displayed by app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:title, :total_items, :size, :resource_type, :description, :creator,
       :contributor, :tag, :rights, :publisher, :date_created, :subject,
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

    def size
      number_to_human_size(Sufia::CollectionSizeService.run(solr_document))
    end

    def total_items
      ActiveFedora::SolrService.query("proxy_in_ssi:#{id}", fl: "ordered_targets_ssim")
        .flat_map { |x| x.fetch("ordered_targets_ssim", []) }.size
    end
  end
end
