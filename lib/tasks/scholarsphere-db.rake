namespace :scholarsphere do
    namespace :db do
      desc "delete all Generic Files in Fedora and Solr (This may take some time...)."
      task :deleteAll => :environment do
        GenericFile.find(:all, limit:GenericFile.count).each {|cf| cf.delete}
      end

      desc "delete 500 Generic Files from Fedora and Solr."
      task :delete500 => :environment do
        GenericFile.find(:all, limit:500).each {|cf| cf.delete}
      end
    
    end

end