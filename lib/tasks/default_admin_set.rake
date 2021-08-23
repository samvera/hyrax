# frozen_string_literal: true
namespace :hyrax do
  namespace :default_admin_set do
    desc "Create the Default Admin Set"
    task create: :environment do
      id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
      if Hyrax::PermissionTemplate.find_by(source_id: id.to_s)
        puts "Successfully created default admin set"
      else
        warn "ERROR: Default admin set exists but it does not have an " \
          "associated permission template.\n\nThis may happen if you cleared your " \
          "database but you did not clear out metadata datasource (e.g. Fedora, Postgres) " \
          "and Solr.\n\n" \
          "You could manually create the permission template in the rails console" \
          " (non-destructive):\n\n" \
          "    Hyrax::PermissionTemplate.create!(source_id: Hyrax::AdminSetCreateService::DEFAULT_ID)\n\n" \
          "OR you could start fresh by clearing the metadata datasource and Solr (destructive):\n\n" \
          "  For ActiveFedora or Wings Valkryie adapter (default), use...\n" \
          "    require 'active_fedora/cleaner'\n" \
          "    ActiveFedora::Cleaner.clean!\n\n" \
          "  For Valkyrie, use...\n" \
          "    conn = Hyrax.index_adapter.connection\n" \
          "    conn.delete_by_query('*:*', params: { 'softCommit' => true })\n" \
          "    Hyrax.persister.wipe!\n"
      end
    end
  end
end
