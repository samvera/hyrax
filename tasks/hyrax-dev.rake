require 'rspec/core/rake_task'
require 'solr_wrapper'   # necessary for rake_support to work
require 'fcrepo_wrapper' # necessary for rake_support to work
require 'engine_cart/rake_task'
require 'rubocop/rake_task'
require 'active_fedora/rake_support'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

RSpec::Core::RakeTask.new(:spec)

desc 'Spin up test servers and run specs'
task :spec_with_app_load  do
  with_test_server do
    Rake::Task['spec'].invoke
  end
end

desc "Sort locales keys in alphabetic order."
task :i18n_sorter do
  require 'i18n_yaml_sorter'
  locales = Dir.glob(File.expand_path('../../config/locales/**/*.yml', __FILE__))
  locales.each do |locale_path|
    sorted_contents = File.open(locale_path) { |f| I18nYamlSorter::Sorter.new(f).sort }
    File.open(locale_path, 'w') { |f|  f << sorted_contents}
    abort("Bad I18n conversion!") unless Psych.load_file(locale_path).is_a?(Hash)
  end
end

desc 'Generate the engine_cart and spin up test servers and run specs'
task ci: ['rubocop', 'engine_cart:generate'] do
  puts 'running continuous integration'
  Rake::Task['spec_with_app_load'].invoke
end
