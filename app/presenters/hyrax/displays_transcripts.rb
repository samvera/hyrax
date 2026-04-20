# frozen_string_literal: true
module Hyrax
  module DisplaysTranscripts
    extend ActiveSupport::Concern

    # @return [Array<SolrDocument>] the solr documents represented by
    # the audio/video file set's transcript_ids
    def transcripts
      return [] if transcript_ids.blank?
      @transcripts ||= begin
                            results = Hyrax::SolrQueryService.new
                                                             .accessible_by(
                                                               ability: (try(:current_ability) || ability),
                                                               action: :read
                                                             )
                                                             .with_ids(ids: transcript_ids)
                                                             .solr_documents
                            sort_transcripts_by_language(results)
                          end
    end

    def transcript_url(document, host: request.base_url, file_ext: "vtt")
      Hyrax::Engine.routes.url_helpers.transcript_url(file_id(document), host: host, file_ext: file_ext)
    end

    # Try our best to convert language field to an ISO 639-1 code for use in the IIIF manifest.
    # @param [Array<String>] - a solr document's language field
    # @return [String or NilClass] - the 2-letter code, or nil if no value or value is unparseable
    def language_code(language)
      return if language.empty?
      value = language.first
      if value.is_a?(ActiveTriples::Resource) || URI.parse(value).scheme
        # This is probably a Library of Congress languages URI
        # like http://id.loc.gov/vocabulary/iso639-3/eng, which can
        # be configured with the Questioning Authority gem.
        # Try to extract the code from the URI.
        value = value.id if value.is_a?(ActiveTriples::Resource)
        LanguageList::LanguageInfo.find(value.split("/").last).try(:iso_639_1)
      else
        # Otherwise, assume it is a language code or name and try
        # to convert it to a 2-letter code
        LanguageList::LanguageInfo.find(value).try(:iso_639_1)
      end
    end

    private
    
    def file_id(document)
      # Try our best to resolve the file id for:
      #   1. the Hyrax::FileMetadata id for a Valkyrie file set
      #   2. the Hyrax::FileMetadata id for an ActiveFedora file set
      document.fetch("file_ids_ssim",[]).first || document.original_file_id
    end

    def sort_transcripts_by_language(results)
      current_locale = I18n.locale.to_s

      # Sort alphabetically by language code
      sorted = results.sort_by { |doc| language_code(doc.language) || '' }

      # Move current locale to front
      sorted.partition { |doc| language_code(doc.language) == current_locale }.flatten
    end
  end
end
