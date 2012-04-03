# Blacklight customization of the Rake tasks that come with rspec-2, to run
# specs located in alternate location (inside BL plugin), and to provide
# rake tasks for jetty/solr wrapping. 
#
# Same tasks as in ordinary rspec, but prefixed with blacklight:. 
#
# rspec2 keeps it's rake tasks inside it's own code, it doesn't generate them. 
# We had to copy them from there and modify, may have to be done again
# if rspec2 changes a lot, but this code looks relatively cleanish. 
begin
  require 'rspec/core'
  require 'rspec/core/rake_task'
  #Rake.application.instance_variable_get('@tasks')['default'].prerequisites.delete('test')
  
  #spec_prereq = Rails.configuration.generators.options[:rails][:orm] == :active_record ?  "db:test:prepare" : :noop
  #task :noop do; end
  spec_prereq = "hyhead:test:prepare" 
  
  hyhead_spec = File.expand_path("../test_support/spec",File.dirname(__FILE__))
  
  # Set env variable to tell our spec/spec_helper.rb where we really are,
  # so it doesn't have to guess with relative path, which will be wrong
  # since we allow spec_dir to be in a remote location. spec_helper.rb
  # needs it before Rails.root is defined there, even though we can
  # oddly get it here, i dunno. 
  #ENV['RAILS_ROOT'] = Rails.root.to_s
  
  namespace :hyhead do
    
    namespace :spec do
      [:controllers, :generators, :helpers, :integration, :lib, :mailers, :models, :requests, :routing, :unit, :utilities, :utilities, :views].each do |sub|
        desc "Run the code examples in spec/#{sub}"
        RSpec::Core::RakeTask.new(sub => spec_prereq) do |t|
        #RSpec::Core::RakeTask.new(sub) do |t|
          # the user might not have run rspec generator because they don't
          # actually need it, but without an ./.rspec they won't get color,
          # let's insist. 
          t.rspec_opts = "--colour"
          
          # pattern directory name defaults to ./**/*_spec.rb, but has a more concise command line echo
          t.pattern = "#{hyhead_spec}/#{sub}" 
        end
      end

    end
  end  
rescue LoadError
  # This rescue pattern stolen from cucumber; rspec didn't need it before since
  # tasks only lived in rspec gem itself, but for Blacklight since we're copying
  # these tasks into BL, we use the rescue so you can still run BL (without
  # these tasks) even if you don't have rspec installed. 
  desc 'rspec rake tasks not available (rspec not installed)'
  task :spec do
    abort 'Rspec rake tasks  not available. Be sure to install rspec gems. '
  end
end

