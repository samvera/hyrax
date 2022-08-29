wipe_data = ActiveModel::Type::Boolean.new.cast(ENV.fetch('WIPE_DATA', false))
seed_release_testing = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SEED_RELEASE_TESTING', false))
seed_koppie = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SEED_KOPPIE', false))

unless wipe_data || seed_release_testing
  puts 'NAME'
  puts '     rails db:seed (Hyrax)'
  puts
  puts 'SYNOPSIS'
  puts '     bundle exec rails db:seed [WIPE_DATA=true|false] [SEED_RELEASE_TESTING=true|false] [SEED_KOPPIE=true|false]'
  puts
  puts 'DESCRIPTION'
  puts '     Hyrax defined db:seed provides a means to clear repository metadata from the datastore (e.g. Fedora, Postgres) and from Solr.'
  puts '     Seeds can be run to pre-populate metadata to help with release testing and local development testing.'
  puts
  puts '     NOTE: Options can be passed in with the command on the command line or set as ENV variables.'
  puts
  puts '     The options are as follows:'
  puts
  puts '     WIPE_DATA'
  puts '             USE WITH CAUTION - Deleted data cannot be recovered.'
  puts
  puts '             When true, it will clear all repository metadata from the datastore (e.g. Fedora, Postgres) and from Solr.  It also'
  puts '             clears data from the application database that are tightly coupled to repository metadata.  See Hyrax::DataMaintenance'
  puts '             for more information on what data will be destroyed by this process.'
  puts
  puts '             The wipe_data process will also restore required repository metadata including collection types and the default admin'
  puts '             set.  See Hyrax::RequiredDataSeeder for more information on what data will be created by this process.'
  puts
  puts '     SEED_RELEASE_TESTING'
  puts '             When true, it will run the set of seeds for release testing creating a repository metadata and support data, including'
  puts '             test users, collection types, collections, and works with and without files.  See Hyrax::TestDataSeeder for more information'
  puts '             on what data will be created by this process.'
  puts
  puts '     SEED_KOPPIE'
  puts '             When true, it will run a minimal set of seeds for koppie test app, including required collection types, default admin set,'
  puts '             and test users.'
  puts
  puts '     ALLOW_RELEASE_SEEDING_IN_PRODUCTION'
  puts '             USE WITH EXTERME CAUTION WHEN USED IN PRODUCTION - Deleted data cannot be recovered.  Attempts are made to not overwrite'
  puts '             existing data, but use in production is not recommended.'
  puts
  puts '             If this is NOT true, the process will abort when Rails environment is production.'
  puts
end

allow_release_seeding_in_production = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ALLOW_RELEASE_SEEDING_IN_PRODUCTION', false))

if Rails.env == 'production' && !allow_release_seeding_in_production
  puts "Seeding data for release testing is not for use in production!"
  exit
end

if wipe_data
  puts '####################################################################################'
  puts
  puts 'WARNING: You are about to clear all repository metadata from the datastore and solr.'
  puts 'Are you sure? [YES|n]'
  answer = STDIN.gets.chomp
  unless answer == 'YES'
    puts '   Aborting!'
    puts '####################################################################################'
    exit
  end

  Hyrax::DataMaintenance.new.destroy_repository_metadata_and_related_data
  Hyrax::RequiredDataSeeder.new.generate_seed_data
end

if seed_koppie
  puts 'Seeding Koppie ...'

  Hyrax::RequiredDataSeeder.new.generate_seed_data
  Hyrax::TestDataSeeders::UserSeeder.generate_seeds
end

if seed_release_testing
  Hyrax::TestDataSeeder.new.generate_seed_data
end
