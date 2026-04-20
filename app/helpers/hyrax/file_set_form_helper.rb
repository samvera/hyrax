# frozen_string_literal: true

module Hyrax
  module FileSetFormHelper
    def render_transcript_ids_field?(file_set)
      return unless file_set.persisted?
      return if Hyrax.custom_queries.find_parent_work(resource: file_set).blank?
      case file_set
      when ActiveFedora::Base
        file_set.video? || file_set.audio?
      when Valkyrie::Resource
        service = Hyrax::FileSetTypeService.new(file_set: file_set)
        service.video? || service.audio?
      end
    end

    def form_transcript_ids_select_for(file_set)
      parent = Hyrax.custom_queries.find_parent_work(resource: file_set)
      options = Forms::FileSetForm.available_transcripts(parent: parent, current_ability: current_ability)
      options.each_with_object({}) do |doc, hash|
        hash[doc.title_or_label] = doc.id.to_s
      end
    end
  end
end
