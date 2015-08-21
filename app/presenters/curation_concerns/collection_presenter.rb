module CurationConcerns
  class CollectionPresenter
    include Hydra::Presenter
    include ActionView::Helpers::NumberHelper

    self.model_class = ::Collection
    # Terms is the list of fields displayed by app/views/collections/_show_descriptions.html.erb
    self.terms = [:title, :total_items, :size, :resource_type, :description, :creator, :contributor,
                  :tag, :rights, :publisher, :date_created, :subject, :language, :identifier,
                  :based_near, :related_url]

    # Depositor and permissions are not displayed in app/views/collections/_show_descriptions.html.erb
    # so don't include them in `terms'.
    # delegate :depositor, :permissions, to: :model

    def terms_with_values
      terms.select { |t| self[t].present? }
    end

    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        super
      end
    end

    def size
      number_to_human_size(model.bytes)
    end

    def total_items
      model.members.count
    end
  end
end
