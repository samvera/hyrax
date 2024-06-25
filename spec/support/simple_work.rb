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

if defined?(Wings)
  Wings::ModelRegistry.register(Hyrax::Test::SimpleWork, Hyrax::Test::SimpleWorkLegacy)
elsif defined?(ActiveFedora) && ENV.key?('FCREPO_BASE_PATH') && Hyrax.config.valkyrie_transition
  # We do not want to add the lazy migration for ActiveFedora to Valkyrie when we don't have a valid
  # Fedora end-point.  Now what is the best way to see if we have a valid and configured fedora
  # connection?
  Hyrax::ValkyrieLazyMigration.migrating(Hyrax::Test::SimpleWork, from: Hyrax::Test::SimpleWorkLegacy)
end
