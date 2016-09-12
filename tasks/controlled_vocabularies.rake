namespace :sufia do
  namespace :controlled_vocabularies do
    desc "Load the lexvo vocabulary into the database"
    task language: :environment do
      require 'sufia/controlled_vocabulary/importer/language'
      Sufia::ControlledVocabulary::Importer::Language.new.import
    end
  end
end
