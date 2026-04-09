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

    # @return [Array<SolrDocument>] the solr documents that correspond to the a/v file set's transcript_ids
    def transcriptions
      return [] if object.transcript_ids.blank?
      @transcriptions ||= begin
                            results = Hyrax::SolrQueryService.new
                                                             .accessible_by(ability: ability, action: :read)
                                                             .with_ids(ids: object.transcript_ids)
                                                             .solr_documents
                            sort_transcriptions_by_language(results)
                          end
    end

    def file_id(doc)
      # Hyrax file sets have file_ids_ssim. ActiveFedora file sets have original_file_id_ssi
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
    # The code is used by IIIF for internationalization.
    # @return [String or NilClass] - the 2-letter code or nil if unparseable
    def coerce_language_type(value)
      return if value.nil?
      if URI.parse(value).scheme
        # This is probably a Library of Congress languages URI
        # like http://id.loc.gov/vocabulary/iso639-3/eng, which can
        # be configured with the Questioning Authority gem.
        # Extract the code from the URI.
        LanguageList::LanguageInfo.find(value.split("/").last).try(:iso_639_1)
      else
        # Otherwise, assume it is a language code or name and try
        # to convert it to a 2-letter code
        LanguageList::LanguageInfo.find(value).try(:iso_639_1)
      end
    end
  end
end
