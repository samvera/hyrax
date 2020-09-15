# frozen_string_literal: true
namespace :hyrax do
  namespace :default_admin_set do
    desc "Create the Default Admin Set"
    task create: :environment do
      id = AdminSet.find_or_create_default_admin_set_id
      # I have found that when I come back to a development
      # environment, that I may have an AdminSet in Fedora, but it is
      # not indexed in Solr.  This remediates that situation by
      # ensuring we have an indexed AdminSet
      AdminSet.find(id).update_index
      if Hyrax::PermissionTemplate.find_by(source_id: id)
        puts "Successfully created default admin set"
      else
        warn "ERROR: Default admin set exists but it does not have an " \
          "associated permission template.\n\nThis may happen if you cleared your " \
          "database but you did not clear out Fedora and Solr.\n\n" \
          "You could manually create the permission template in the rails console" \
          " (non-destructive):\n\n" \
          "    Hyrax::PermissionTemplate.create!(source_id: AdminSet::DEFAULT_ID)\n\n" \
          "OR you could start fresh by clearing Fedora and Solr (destructive):\n\n" \
          "    require 'active_fedora/cleaner'\n" \
          "    ActiveFedora::Cleaner.clean!\n\n"
      end
    end
  end
end
