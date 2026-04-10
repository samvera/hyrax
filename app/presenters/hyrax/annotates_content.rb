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
      transcriptions.map do |doc|
        IIIFManifest::V3::AnnotationContent.new(
          type: 'Annotation',
          motivation: 'supplementing',
          body_id: transcript_url(doc.original_file_id, host: hostname),
          format: 'text/vtt',
          label: doc.title_or_label || 'Captions',
          language: language_code(doc.language)
        )
      end
    end
    
  end
end
