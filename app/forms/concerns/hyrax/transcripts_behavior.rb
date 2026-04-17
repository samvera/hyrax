# frozen_string_literal: true
module Hyrax
  module TranscriptsBehavior
    extend ActiveSupport::Concern

    def self.included(descendant)
      descendant.property :transcript_ids, type: Valkyrie::Types::Array.of(Valkyrie::Types::ID)
    end

    class_methods do
      def available_transcripts(parent:, current_ability:)
        Hyrax::SolrQueryService.new
                               .with_model(model: Hyrax.config.file_set_class.to_s)
                               .with_ids(ids: parent.member_ids.map(&:to_s))
                               .accessible_by(ability: current_ability, action: :edit)
                               .solr_documents(
                                 fq: mime_type_filter_query.to_s,
                                 fl: "id,title_tesim",
                                 rows: 1000
                               )
      end

      private

      def mime_type_filter_query
        valid_mime_types.map { |type| "mime_type_ssi:\"#{type}\"" }.join(" OR ")
      end

      # According to IIIF, .srt and .ttml are also acceptable but may
      # not be supported by viewers. Clover and Ramp are confirmed to work
      # with .vtt. (https://iiif.io/api/cookbook/recipe/0219-using-caption-file/).
      # When Hyrax supports Ramp, we may want to add "text/plain" (.srt) to this list.
      def valid_mime_types
        ["text/vtt"]
      end
    end
  end
end
