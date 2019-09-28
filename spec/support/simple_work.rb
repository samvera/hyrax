# frozen_string_literal: true

module Hyrax
  module Test
    class SimpleWork < Hyrax::Resource
      include Hyrax::Schema(:core_metadata)
    end

    class SimpleWorkLegacy < ActiveFedora::Base
      include WorkBehavior
      include CoreMetadata
    end
  end
end

Wings::ModelRegistry.register(Hyrax::Test::SimpleWork, Hyrax::Test::SimpleWorkLegacy)
