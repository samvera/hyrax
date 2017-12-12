namespace :hyrax do
  desc 'Print a count of each object type'
  task count: [:environment] do
    Rails.application.eager_load!
    puts "Number of objects in the repository:"
    solr = Valkyrie::MetadataAdapter.find(:index_solr).connection
    Valkyrie::Resources.descendants.each do |model|
      results = solr.get('select', params: { q: "{!field f=internal_resource_ssim}#{model}",
                                             rows: 0,
                                             qt: 'standard' })
      puts "  #{model}: #{results['response']['numFound']}"
    end
  end
end
