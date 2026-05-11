# frozen_string_literal: true

module Hyrax
  module AnnotatesContent
    extend ActiveSupport::Concern

    def annotation_content
      transcription_content if video? || audio?
    end

    private

    def transcription_content
      transcriptions.map do |hash|
        IIIFManifest::V3::AnnotationContent.new(
          type: 'Annotation',
          motivation: 'supplementing',
          body_id: captions_url(hash['file_ids_ssim'].first),
          format: 'text/vtt',
          label: hash['title_tesim']&.first || 'Captions',
          language: hash['language_tesim']&.first || 'en'
        )
      end
    end

    def transcriptions
      @transcriptions ||= begin
        parent = Hyrax::SolrService.query("member_ids_ssim:#{id}", rows: 1, fl: "member_ids_ssim").first
        member_ids = parent['member_ids_ssim']
        mime_type = 'text/vtt'
        fl = 'title_tesim,language_tesim,file_ids_ssim'
        results = Hyrax::SolrService.query("id:(#{member_ids.join(' OR ')}) AND mime_type_ssi:#{mime_type}", rows: 100, fl: fl)

        sort_transcriptions_by_language(results)
      end
    end

    def captions_url(file_id)
      Hyrax::Engine.routes.url_helpers.transcription_url(file_id, host: hostname)
    end

    def sort_transcriptions_by_language(results)
      current_locale = I18n.locale.to_s

      # Sort alphabetically by language code
      sorted = results.sort_by { |hash| hash['language_tesim']&.first || '' }

      # Move current locale to front
      sorted.partition { |hash| hash['language_tesim']&.first == current_locale }.flatten
    end
  end
end
