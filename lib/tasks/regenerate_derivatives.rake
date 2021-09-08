# frozen_string_literal: true

namespace :hyrax do
  namespace :file_sets do
    desc 'Regenerate derivatives for all FileSets in the repository'
    task :regenerate_derivatives do
      FileSet.all.each do |fs|
        fs.files.each { |fi| CreateDerivativesJob.perform_later(fs, fi) }
      end
    end
  end
end
