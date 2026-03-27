# frozen_string_literal: true
module Hyrax
  class FileSet
    module Transcripts
      extend ActiveSupport::Concern

      # Add transcript_ids to the Schema
      # class TranscriptIdsSchema < ActiveTriples::Schema
      #   property :transcript_ids, predicate: ::RDF::URI.new('http://vocabulary.samvera.org/ns#transcriptIds'), multiple: true
      # end
      # ::FileSet::GeneratedResourceSchema << TranscriptIdsSchema

      included do
        property :transcript_ids, predicate: ::RDF::URI.new('http://vocabulary.samvera.org/ns#transcriptIds'), multiple: true do |index|
          index.as :stored_sortable
        end
      end
    end
  end
end
