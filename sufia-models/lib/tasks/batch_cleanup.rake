namespace :sufia do

  desc "Reports on and optionally removes empty batches that contain no associated files"
  task :empty_batches, [:remove] => :environment do |t, args|
    option = args.to_hash.fetch(:remove, "keep")
    Batch.all.each do |batch|
      if batch.generic_files.empty?
        print "#{batch.id} contains no files - "
        if option == "remove"
          batch.destroy
          puts "deleted"
        else
          puts "to delete, rerun with the remove option: rake sufia:empty_batches[remove]"
        end
      end
    end
  end

end
