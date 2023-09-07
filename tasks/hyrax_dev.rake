# frozen_string_literal: true
require 'English'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

RSpec::Core::RakeTask.new(:spec)

desc "Sort locales keys in alphabetic order."
task :i18n_sorter do
  require 'i18n_yaml_sorter'
  locales = Dir.glob(File.expand_path('../../config/locales/**/*.yml', __FILE__)) +
            Dir.glob(File.expand_path('../../lib/generators/hyrax/templates/config/locales/**/*.yml', __FILE__)) +
            Dir.glob(File.expand_path('../../lib/generators/hyrax/work/templates//locale.*.yml.erb', __FILE__))
  locales.each do |locale_path|
    sorted_contents = File.open(locale_path) { |f| I18nYamlSorter::Sorter.new(f).sort }
    File.open(locale_path, 'w') { |f| f << sorted_contents }
    abort("Bad I18n conversion!") unless Psych.load_file(locale_path).is_a?(Hash)
  end
end

desc 'Run rubocop and then run specs'
task ci: ['rubocop'] do
  puts 'running continuous integration'
  Rake::Task['spec_with_app_load'].invoke
end
