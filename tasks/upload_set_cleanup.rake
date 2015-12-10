namespace :sufia do

  desc "Reports on and optionally removes empty upload_sets that contain no associated files"
  task :empty_upload_sets, [:remove] => :environment do |t, args|
    option = args.to_hash.fetch(:remove, "keep")
    UploadSet.all.each do |upload_set|
      if upload_set.works.empty?
        print "#{upload_set.id} contains no files - "
        if option == "remove"
          upload_set.destroy
          puts "deleted"
        else
          puts "to delete, rerun with the remove option: rake sufia:empty_upload_sets[remove]"
        end
      end
    end
  end

end
