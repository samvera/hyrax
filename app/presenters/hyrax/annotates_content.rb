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
        options = {
          type: 'Text',
          motivation: 'supplementing',
          body_id: transcript_url(doc, host: hostname, file_ext: file_ext(doc.mime_type)),
          format: doc.mime_type,
          label: doc.title_or_label
        }
        options[:language] = language_code(doc.language) if language_code(doc.language)
        IIIFManifest::V3::AnnotationContent.new(**options)
      end
    end

    # If you change the accepted mime types in Hyrax::TranscriptsBehavior,
    # you may also want to override this method
    def file_ext(_mime_type)
      "vtt"
    end
  end
end
