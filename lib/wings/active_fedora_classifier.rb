# frozen_string_literal: true

module Wings
  class ActiveFedoraClassifier < ActiveFedora::ModelClassifier
    private

    def classify(model_value)
      if (match = model_value.match(/Wings\((.*)\)/))
        valkyrie_class = match[1].constantize
        if valkyrie_class <= Hyrax::FileMetadata
          Wings::ActiveFedoraConverter::FileMetadataNode(valkyrie_class)
        else
          Wings::ActiveFedoraConverter::DefaultWork(valkyrie_class)
        end
      else
        super
      end
    end
  end
end
