# frozen_string_literal: true

module Hyrax
  module Test
    class SimpleWork < Hyrax::Resource
      # use the *private* initalizer here to ensure the module gets loaded
      # use `include Hyrax::Schema(:core_metadata)
      include Hyrax::Schema(:core_metadata)
    end

    class SimpleWorkLegacy < ActiveFedora::Base
      include WorkBehavior
      include CoreMetadata
    end
  end
end

Wings::ModelRegistry.register(Hyrax::Test::SimpleWork, Hyrax::Test::SimpleWorkLegacy)
