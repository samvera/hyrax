namespace :hyrax do
  namespace :reset do
    desc 'Reset fedora / solr and corrisponding database tables w/o clearing other active record tables like users'
    task works_and_collections: [:environment] do
      confirm('You are about to delete all works and collections, this is not reversable!')
      require 'active_fedora/cleaner'
      ActiveFedora::Cleaner.clean!
      Hyrax::PermissionTemplateAccess.delete_all
      Hyrax::PermissionTemplate.delete_all

      # we need to wait till Fedora is done with its cleanup
      # otherwise creating the admin set will fail
      while AdminSet.exists?(AdminSet::DEFAULT_ID)
        puts 'waiting for delete to finish before reinitializing Fedora'
        sleep 20
      end
      Rake::Task["hyrax:default_collection_types:create"].invoke
      Rake::Task["hyrax:default_admin_set:create"].invoke
    end

    def confirm(action)
      return if ENV['RESET_CONFIRMED'].present?
      confirm_token = rand(36**6).to_s(36)
      STDOUT.puts "#{action} Enter '#{confirm_token}' to confirm:"
      input = STDIN.gets.chomp
      raise "Aborting. You entered #{input}" unless input == confirm_token
    end
  end
end
