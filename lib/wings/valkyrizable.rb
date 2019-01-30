# frozen_string_literal: true

module Wings
  module Valkyrizable
    ##
    # @return [Valkyrie::Resource] a valkyrie resource matching this model
    def valkyrie_resource
      ResourceFactory.for(self)
    end
  end
end
