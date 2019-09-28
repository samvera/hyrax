# frozen_string_literal: true

module Hyrax
  class WorkFormService
    def self.build(curation_concern, current_ability, *extra)
      form_class(curation_concern).new(curation_concern, current_ability, *extra)
    end

    ##
    # @param [ActiveFedora::Base, Valkyrie::Resource] curation_concern
    def self.form_class(curation_concern)
      case curation_concern
      when ActiveFedora::Base
        Hyrax.const_get("#{curation_concern.model_name.name}Form")
      when Valkyrie::Resource
        Hyrax::Forms::ChangeSetForm
      end
    end
  end
end
