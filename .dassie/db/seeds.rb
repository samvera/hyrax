# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
if ENV["RAILS_SKIP_SEEDS"] == "false"
  puts '==========================='
  puts ' Running Database Seeds '
  puts '==========================='
  case Rails.env
  when "development", "integration"
    puts "Cleaning out Fedora and Solr"
    require 'active_fedora/cleaner'
    ActiveFedora::Cleaner.clean!
    # PermissionTemplates are tightly coupled to admin sets and collections.  When they are removed using clean!, the
    # associated database entries for permission templates also have to be deleted.
    Hyrax::PermissionTemplateAccess.destroy_all
    Hyrax::PermissionTemplate.destroy_all
  end
  Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')].sort.each { |seed| load seed }
end
