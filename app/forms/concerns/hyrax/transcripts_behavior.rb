# frozen_string_literal: true
module Hyrax
  module TranscriptsBehavior
    extend ActiveSupport::Concern

    class_methods do
      def available_transcripts(parent:, current_ability:)
         member_ids = Hyrax.custom_queries.find_child_file_set_ids(resource: parent)
         Hyrax::SolrQueryService.new
                                # Cast Valkyrie::IDs to strings
                                .with_ids(ids: member_ids.map(&:to_s).to_a)
                                .accessible_by(ability: current_ability, action: :edit)
                                .solr_documents(
                                  # Using "has_model_ssim:*FileSet" in fq will return both FileSet
                                  # and Hyrax::FileSet documents. In test mode, Koppie and Sirenia 
                                  # index file sets with has_model_ssim:Hyrax::FileSet. 
                                  # But in dev mode, they index file sets with 
                                  # has_model_ssim:FileSet instead. This query covers both cases.
                                  fq: [mime_type_filter_query.to_s, "has_model_ssim:*FileSet"],
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
