# frozen_string_literal: true

module Hyrax
  ##
  # Determines which characterizer to run based on the file_set type
  # allowing implementation of Valkyrie file_sets
  class Characterizer
    ##
    # @param source: the object to run a characterizer on
    #
    # @return [#characterize]
    def self.for(source:)
      case source
      when Hyrax::FileSetBehavior # ActiveFedora
        FileSetCharacterizer.new(source: source)
      when Hyrax::FileSet # Valkyrie
        ResourceCharacterizer.new(source: source)
      end
    end
  end
end
