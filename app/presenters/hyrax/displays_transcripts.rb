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

    def transcript_url(file_id, host: request.base_url, file_ext: "vtt")
      Hyrax::Engine.routes.url_helpers.transcript_url(file_id, host: host, file_ext: file_ext)
    end

    # Convert language field to a 2-letter code, if possible.
    # The code is used by IIIF for internationalization.
    # @param [Array<String>] - a solr document's language field
    # @return [String] - the 2-letter code, or "en" if no values or value is unparseable
    def language_code(language)
      value = language.try(:first)
      return "en" if value.nil?
      code = if URI.parse(value).scheme
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
      (code || "en")
    end

    private

    def sort_transcripts_by_language(results)
      current_locale = I18n.locale.to_s

      # Sort alphabetically by language code
      sorted = results.sort_by { |doc| language_code(doc.language) }

      # Move current locale to front
      sorted.partition { |doc| language_code(doc.language) == current_locale }.flatten
    end
  end
end
