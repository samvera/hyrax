module Hyrax
  class ContextualPath
    include Rails.application.routes.url_helpers
    include ActionDispatch::Routing::PolymorphicRoutes
    attr_reader :presenter, :parent_presenter
    def initialize(presenter, parent_presenter)
      @presenter = presenter
      @parent_presenter = parent_presenter
    end

    def show
      if parent_presenter
        polymorphic_path([:hyrax, :parent, presenter.model_name.singular.to_sym],
                         parent_id: parent_presenter.id,
                         id: presenter.id)
      else
        polymorphic_path([presenter])
      end
    end
  end
end
