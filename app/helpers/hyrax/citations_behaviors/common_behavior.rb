# frozen_string_literal: true
module Hyrax
  module CitationsBehaviors
    module CommonBehavior
      def persistent_url(work)
        "#{Hyrax.config.persistent_hostpath}#{work.id}"
      end

      def clean_end_punctuation(text)
        return text[0, text.length - 1] if text && ([".", ",", ":", ";", "/"].include? text[-1, 1])
        text
      end
    end
  end
end
