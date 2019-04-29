namespace :hyrax do
  namespace :universal_viewer do
    desc "Install Universal Viewer"
    task install: :environment do
      # Copy the files into place
      hyrax_templates_path = File.join(Gem.loaded_specs['hyrax'].full_gem_path, 'lib', 'generators', 'hyrax', 'templates')
      copy_file File.join(hyrax_templates_path, 'package.json'), Rails.root.join('package.json')
      Dir.mkdir(Rails.root.join('config', 'uv')) unless File.exist?(Rails.root.join('config', 'uv'))
      copy_file File.join(hyrax_templates_path, 'uv.html'), Rails.root.join('config', 'uv', 'uv.html')
      copy_file File.join(hyrax_templates_path, 'uv-config.json'), Rails.root.join('config', 'uv', 'uv-config.json')

      puts 'Universal Viewer (UV) configs copied into place, install UV by running yarn install or rake assets:precompile'
    end
  end
end
