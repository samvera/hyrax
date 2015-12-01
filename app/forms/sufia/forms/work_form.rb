module Sufia::Forms
  class WorkForm < CurationConcerns::Forms::WorkForm
    delegate :depositor, :permissions, to: :model

    def rendered_terms
      terms - [:visibility]
    end
  end
end
