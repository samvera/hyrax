# frozen_string_literal: true

module Hyrax
  module AnnotatesContent
    extend ActiveSupport::Concern

    include DisplaysTranscripts

    def annotation_content
      transcription_content if video? || audio?
    end

    private

    def transcription_content
      transcripts.map do |doc|
        IIIFManifest::V3::AnnotationContent.new(
          type: 'Text',
          motivation: 'supplementing',
          body_id: transcript_url(doc.original_file_id, host: hostname, file_ext: file_ext(doc.mime_type)),
          format: doc.mime_type,
          label: doc.title_or_label || I18n.t("hyrax.captions", language: language_code(doc.language)),
          language: language_code(doc.language)
        )
      end
    end

    # If you change the accepted mime types in Hyrax::TranscriptsBehavior,
    # you may also want to override this method
    def file_ext(_mime_type)
      "vtt"
    end
  end
end
