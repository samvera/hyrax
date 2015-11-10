module Sufia
  module Forms
    class BatchEditForm < CurationConcerns::Forms::FileSetEditForm
      self.terms = [:resource_type, :title, :creator, :contributor, :description,
              :tag, :rights, :publisher, :date_created, :subject, :language,
              :identifier, :based_near, :related_url]
    end
  end
end
