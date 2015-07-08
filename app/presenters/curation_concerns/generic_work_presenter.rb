module CurationConcerns
  class GenericWorkPresenter
    include Hydra::Presenter
    self.model_class = GenericWork
    # Terms is the list of fields displayed
    self.terms = [:resource_type, :title, :creator, :contributor, :description, :tag, :rights,
       :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url]

    # Depositor and permissions are not displayed
    # so don't include them in `terms'.
    delegate :depositor, :permissions, to: :model
  end
end
