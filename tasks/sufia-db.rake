namespace :sufia do
  namespace :db do
    desc "delete all Generic Files in Fedora and Solr (This may take some time...)."
    task :deleteAll => :environment do
      unless Rails.env.integration?
        puts "Warning: this task is only for the integration environment!"
        next
      end
      GenericFile.find(:all, :rows => GenericFile.count).each(&:delete)
    end

    desc "delete 500 Generic Files from Fedora and Solr."
    task :delete500 => :environment do
      unless Rails.env.integration?
        puts "Warning: this task is only for the integration environment!"
        next
      end
      GenericFile.find(:all, :rows => 500).each(&:delete)
    end
  end
end
