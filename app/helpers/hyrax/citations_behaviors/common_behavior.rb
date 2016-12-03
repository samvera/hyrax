module Hyrax
  module CitationsBehaviors
    module CommonBehavior
      def persistent_url(work)
        "#{Hyrax.config.persistent_hostpath}#{work.id}"
      end

      def clean_end_punctuation(text)
        if text && ([".", ",", ":", ";", "/"].include? text[-1, 1])
          return text[0, text.length - 1]
        end
        text
      end
    end
  end
end
