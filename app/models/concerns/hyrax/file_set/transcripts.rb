# frozen_string_literal: true
module Hyrax
  class FileSet
    module Transcripts
      extend ActiveSupport::Concern

      included do
        if Hyrax.config.file_set_include_metadata?
          property :transcript_ids, predicate: ::RDF::URI.new('http://vocabulary.samvera.org/ns#transcriptIds'), multiple: true do |index|
            index.as :stored_sortable
          end
        end
      end
    end
  end
end
