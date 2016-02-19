namespace :curation_concerns do
  desc 'Print a count of each object type'
  task count: [:environment] do
    Rails.application.eager_load!
    puts "Number of objects in fedora:"
    ActiveFedora::Base.descendants.each do |model|
      puts "  #{model}: #{model.count}"
    end
  end
end
