# frozen_string_literal: true
namespace :hyrax do
  namespace :controlled_vocabularies do
    desc "Load the lexvo vocabulary into the database"
    task language: :environment do
      require 'hyrax/controlled_vocabulary/importer/language'
      Hyrax::ControlledVocabulary::Importer::Language.new.import
    end
  end
end
