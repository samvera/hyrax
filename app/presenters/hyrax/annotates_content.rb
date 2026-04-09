# frozen_string_literal: true

module Hyrax
  module AnnotatesContent
    extend ActiveSupport::Concern

    def annotation_content
      transcription_content if video? || audio?
    end

    private

    def transcription_content
      transcriptions.map do |doc|
        IIIFManifest::V3::AnnotationContent.new(
          type: 'Annotation',
          motivation: 'supplementing',
          body_id: captions_url(file_id(doc)),
          format: 'text/vtt',
          label: doc['title_tesim']&.first || 'Captions',
          language: coerce_language_type(doc.language&.first) || 'en'
        )
      end
    end

    def transcriptions
      return [] if self.object.transcript_ids.blank?
      @transcriptions ||= begin
                            results = Hyrax::SolrQueryService.new
                                                             .accessible_by(ability: ability, action: :read)
                                                             .with_ids(ids: self.object.transcript_ids)
                                                             .solr_documents
                            sort_transcriptions_by_language(results)
                          end
    end
    
    def file_id(doc)
      return doc['file_ids_ssim'].first if doc['file_ids_ssim']
      doc['original_file_id_ssi']
    end

    def captions_url(file_id)
      Hyrax::Engine.routes.url_helpers.transcription_url(file_id, host: hostname)
    end

    def sort_transcriptions_by_language(results)
      current_locale = I18n.locale.to_s

      # Sort alphabetically by language code
      sorted = results.sort_by { |doc| coerce_language_type(doc.language&.first) || '' }

      # Move current locale to front
      sorted.partition { |doc| coerce_language_type(doc.language&.first) == current_locale }.flatten
    end
    
    # Convert language value to a 2-letter code, if possible.
    # This is used by IIIF for internationalization.
    def coerce_language_type(value)
      return if value.nil?
      if URI.parse(value).scheme
        # This is probably a Library of Congress languages URI
        # like http://id.loc.gov/vocabulary/iso639-3/eng.
        # Extract the code from the URI
        LanguageList::LanguageInfo.find(value.split("/").last).try(:iso_639_1)
      else
        # Otherwise, assume it is a language code/name and try
        # to convert it to a 2-letter code
        LanguageList::LanguageInfo.find(value).try(:iso_639_1)
      end
    end
  end
end