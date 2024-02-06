# frozen_string_literal: true

module Hyrax
  module Test
    ##
    # A generic PCDM Work, with only Hyrax "core" (required) metadata.
    #
    # @example building with FactoryBot
    #   work = FactoryBot.build(:hyrax_work, :public, title: ['Comet in Moominland'])
    #
    # @example creating with FactoryBot
    #   work = FactoryBot.valkyrie_create(:hyrax_work, :public, title: ['Comet in Moominland'])
    class SimpleWork < Hyrax::Work
    end

    class SimpleWorkLegacy < ActiveFedora::Base
      include WorkBehavior
      include CoreMetadata
    end

    class SimpleWorkSearchBuilder < Hyrax::WorkSearchBuilder
      def work_types
        [Hyrax::Test::SimpleWorkLegacy]
      end
    end
  end
end

Wings::ModelRegistry.register(Hyrax::Test::SimpleWork, Hyrax::Test::SimpleWorkLegacy) if defined?(Wings)

# We do not want to add the lazy migration for ActiveFedora to Valkyrie when we don't have a valid
# Fedora end-point.  The best in test approximation of this is by way of whether or not we have
# disabled wings; wings only makes sense when you have an ActiveFedora-based application.
Hyrax::ValkyrieLazyMigration.migrating(Hyrax::Test::SimpleWork, from: Hyrax::Test::SimpleWorkLegacy) unless Hyrax.config.disable_wings
