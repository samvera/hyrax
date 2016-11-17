module CurationConcerns
  class WorkFormService
    def self.build(curation_concern, current_ability, *extra)
      form_class(curation_concern).new(curation_concern, current_ability, *extra)
    end

    def self.form_class(curation_concern)
      CurationConcerns.const_get("#{curation_concern.model_name.name}Form")
    end
  end
end
