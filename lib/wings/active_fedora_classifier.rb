# frozen_string_literal: true

module Wings
  class ActiveFedoraClassifier < ActiveFedora::ModelClassifier
    private

      def classify(model_value)
        if (match = model_value.match(/Wings\((.*)\)/))
          valkyrie_class = match[1].constantize
          Wings::ActiveFedoraConverter::DefaultWork(valkyrie_class)
        else
          super
        end
      end
  end
end
