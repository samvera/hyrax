wipe_data = ActiveModel::Type::Boolean.new.cast(ENV.fetch('WIPE_DATA', false))
wipe_and_seed_release_testing = ActiveModel::Type::Boolean.new.cast(ENV.fetch('WIPE_AND_SEED_RELEASE_TESTING', false))
seed_release_testing = ActiveModel::Type::Boolean.new.cast(ENV.fetch('SEED_RELEASE_TESTING', false))

unless wipe_data || wipe_and_seed_release_testing || seed_release_testing
  puts 'NAME'
  puts '     rails db:seed (Hyrax)'
  puts
  puts 'SYNOPSIS'
  puts '     bundle exec rails db:seed [wipe_data=true|false] [seed_release_testing=true|false] [wipe_and_seed_release_testing=true|false]'
  puts
  puts 'DESCRIPTION'
  puts '     Hyrax defined db:seed provides a means to clear repository metadata from the datastore (e.g. Fedora, Postgres) and from Solr.'
  puts '     Seeds can be run to pre-populate metadata to help with release testing and local development testing.'
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
  puts '     WIPE_AND_SEED_RELEASE_TESTING'
  puts '             USE WITH CAUTION - Deleted data cannot be recovered.'
  puts
  puts '             When true, it perform both the wipe_data and seed_release_testing options.  See those options for more information.'
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

if wipe_and_seed_release_testing || wipe_data
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

if wipe_and_seed_release_testing || seed_release_testing
  Hyrax::TestDataSeeder.new.generate_seed_data
end

puts
puts 'seed process complete'
puts '---------------------'
