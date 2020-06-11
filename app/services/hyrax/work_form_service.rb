# frozen_string_literal: true
module Hyrax
  ##
  # A factory that builds work forms based on the `#model_name` of the work.
  class WorkFormService
    def self.build(curation_concern, current_ability, *extra)
      form_class(curation_concern).new(curation_concern, current_ability, *extra)
    end

    def self.form_class(curation_concern)
      Hyrax.const_get("#{curation_concern.model_name.name}Form")
    end
  end
end
